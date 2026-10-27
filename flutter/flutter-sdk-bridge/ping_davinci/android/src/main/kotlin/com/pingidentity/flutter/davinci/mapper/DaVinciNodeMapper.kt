/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.davinci.module.Detail
import com.pingidentity.davinci.module.category
import com.pingidentity.davinci.module.continueNode
import com.pingidentity.davinci.module.description
import com.pingidentity.davinci.module.id
import com.pingidentity.davinci.module.name
import com.pingidentity.davinci.plugin.CollectorFactory
import com.pingidentity.davinci.plugin.collectors
import com.pingidentity.flutter.core.mapper.JsonBridgeMapper
import com.pingidentity.flutter.davinci.NodeMessage
import com.pingidentity.flutter.davinci.NodeType
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.orchestrate.SuccessNode
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Maps a native [Node] to the wire-serializable [NodeMessage]. Exposes the DaVinci `ContinueNode`
 * extension properties (`id`, `name`, `description`, `category`) as real fields.
 *
 * An [ErrorNode] carries its decoded `details()` and, when it is retryable, the page fields and
 * collectors of the `ContinueNode` it can be retried from. Session and user data are added by
 * later phases; a [SuccessNode] carries only its type for now.
 */
internal object DaVinciNodeMapper {
    fun map(node: Node): NodeMessage =
        when (node) {
            is ContinueNode -> mapContinueNode(node)
            is SuccessNode -> NodeMessage(type = NodeType.SUCCESS_NODE)
            is ErrorNode -> mapErrorNode(node)
            is FailureNode ->
                NodeMessage(
                    type = NodeType.FAILURE_NODE,
                    cause = node.cause.message ?: node.cause.toString(),
                )
        }

    /**
     * The `id`/`name`/`description`/`category` extensions cast to the SDK's internal `Connector`,
     * which every DaVinci `ContinueNode` is, so a hand-built `ContinueNode` can't go through here.
     */
    private fun mapContinueNode(node: ContinueNode): NodeMessage =
        NodeMessage(
            type = NodeType.CONTINUE_NODE,
            id = node.id,
            name = node.name,
            pageDescription = node.description,
            category = node.category,
            collectors = DaVinciCollectorMapper.map(node.collectors, node.input),
            unsupportedFields =
                unsupportedFields(node.input, CollectorFactory.collectors().keys).ifEmpty { null },
        )

    /**
     * The retry node is `ErrorNode.continueNode()`: the node that was just submitted, which the SDK
     * keeps in the flow context. The SDK closed it on submit, so its password collectors are empty
     * again, while every other collector keeps the value that was sent.
     */
    private fun mapErrorNode(node: ErrorNode): NodeMessage {
        val retry = node.continueNode()?.let(::mapContinueNode)
        return NodeMessage(
            type = NodeType.ERROR_NODE,
            message = node.message,
            status = node.status?.toLong(),
            input = encodeInput(node.input),
            errorDetails = errorDetails(node.input).ifEmpty { null },
            id = retry?.id,
            name = retry?.name,
            pageDescription = retry?.pageDescription,
            category = retry?.category,
            collectors = retry?.collectors,
            unsupportedFields = retry?.unsupportedFields,
        )
    }

    /**
     * `ErrorNode.details()` as wire maps (see `NodeMessage.errorDetails`), decoded with the SDK's
     * own [Detail] serializer but not with `details()` itself, which fails on real responses.
     *
     * - `RawResponse` and `ErrorDetail` declare their fields `String?` with no default, which
     *   kotlinx.serialization treats as required. A sign-on for an unknown user answers with a
     *   `rawResponse` that is a user-search result, with no `id`/`code`/`message`, so `details()`
     *   throws `MissingFieldException` (ping-android-sdk 2.2.0, SDKS-5536). iOS reads absent
     *   keys as `nil`; [detailsJson]'s `explicitNulls = false` does the same here.
     * - `details()` decodes the array in one go, so one malformed element (no `statusCode`, say)
     *   loses the others, where iOS drops just that element. Decoding per element matches iOS.
     *
     * One divergence is left: an `innerError` without `unsatisfiedRequirements` decodes here to an
     * empty map, but fails its whole detail on iOS. Real bodies always carry it.
     */
    // TODO(SDKS-5536): call ErrorNode.details() once it decodes absent nullable keys and keeps the
    // elements it can decode.
    internal fun errorDetails(input: JsonObject): List<Any?> {
        val details = input["details"] as? JsonArray ?: return emptyList()
        return details.mapNotNull { element ->
            runCatching { detailsJson.decodeFromJsonElement(Detail.serializer(), element) }
                .getOrNull()
                ?.let(::detail)
        }
    }

    private fun detail(detail: Detail): Map<String?, Any?> =
        mapOf(
            "statusCode" to detail.statusCode.toLong(),
            "rawResponse" to
                mapOf(
                    "id" to detail.rawResponse.id,
                    "code" to detail.rawResponse.code,
                    "message" to detail.rawResponse.message,
                    "details" to
                        detail.rawResponse.details?.map { error ->
                            mapOf(
                                "code" to error.code,
                                "target" to error.target,
                                "message" to error.message,
                                "innerError" to error.innerError?.errors,
                            )
                        },
                ),
        )

    /** The SDK's internal `json` setting (`ignoreUnknownKeys`), plus absent nullable keys as null. */
    @OptIn(ExperimentalSerializationApi::class)
    private val detailsJson =
        Json {
            ignoreUnknownKeys = true
            explicitNulls = false
        }

    /**
     * The form fields the collector factory dropped, as `{key, type}` maps: those whose lookup key
     * — `inputType`, falling back to `type`, exactly as `CollectorFactory.collector()` resolves
     * it — has no registered collector. Android's factory never drops a registered field, so
     * [registered] (the factory's keys, add-ons included) decides it exactly. Unlike RN v1.1.0's
     * key-based diff, key-less fields (`ERROR_DISPLAY`) are reported too, with a `null` key.
     */
    internal fun unsupportedFields(input: JsonObject, registered: Set<String>): List<Any?> {
        val form = input["form"] as? JsonObject
        val components = form?.get("components") as? JsonObject
        val fields = components?.get("fields") as? JsonArray ?: return emptyList()
        return fields.mapNotNull { element ->
            val field = element as? JsonObject ?: return@mapNotNull null
            val type = field.string("inputType") ?: field.string("type") ?: return@mapNotNull null
            if (type in registered) null else mapOf<String?, Any?>("key" to field.string("key"), "type" to type)
        }
    }

    private fun JsonObject.string(name: String): String? =
        (this[name] as? JsonPrimitive)?.takeIf { it.isString }?.content

    @Suppress("UNCHECKED_CAST")
    private fun encodeInput(input: kotlinx.serialization.json.JsonObject): Map<String?, Any?>? =
        JsonBridgeMapper.encodeJsonElement(input) as? Map<String?, Any?>
}
