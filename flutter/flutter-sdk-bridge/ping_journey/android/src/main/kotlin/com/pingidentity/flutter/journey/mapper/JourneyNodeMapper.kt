/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.mapper

import com.pingidentity.flutter.journey.CallbackMessage
import com.pingidentity.flutter.journey.NodeMessage
import com.pingidentity.flutter.journey.NodeType
import com.pingidentity.journey.callback.AbstractValidatedCallback
import com.pingidentity.journey.callback.AttributeInputCallback
import com.pingidentity.journey.plugin.AbstractCallback
import com.pingidentity.journey.callback.BooleanAttributeInputCallback
import com.pingidentity.journey.callback.ChoiceCallback
import com.pingidentity.journey.callback.KbaCreateCallback
import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.journey.callback.NumberAttributeInputCallback
import com.pingidentity.journey.callback.PasswordCallback
import com.pingidentity.journey.callback.StringAttributeInputCallback
import com.pingidentity.journey.callback.TermsAndConditionsCallback
import com.pingidentity.journey.callback.TextInputCallback
import com.pingidentity.journey.callback.TextOutputCallback
import com.pingidentity.journey.callback.ValidatedPasswordCallback
import com.pingidentity.journey.callback.ValidatedUsernameCallback
import com.pingidentity.journey.plugin.Callback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.journey.plugin.description
import com.pingidentity.journey.plugin.header
import com.pingidentity.journey.plugin.stage
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.orchestrate.SuccessNode
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonPrimitive

/**
 * Maps a native [Node] to the wire-serializable [NodeMessage], including full per-callback field
 * mapping for the v1 callback set. Exposes `header`/`description`/`stage` as real fields (this
 * SDK's `journey-plugin` `ContinueNode` extension properties) rather than as an opaque
 * passthrough blob.
 */
internal object JourneyNodeMapper {
    fun map(node: Node): NodeMessage =
        when (node) {
            is ContinueNode ->
                NodeMessage(
                    type = NodeType.CONTINUE_NODE,
                    header = node.header,
                    pageDescription = node.description,
                    stage = node.stage,
                    callbacks = mapCallbacks(node),
                )
            is SuccessNode -> NodeMessage(type = NodeType.SUCCESS_NODE)
            is ErrorNode ->
                NodeMessage(
                    type = NodeType.ERROR_NODE,
                    message = node.message,
                    status = node.input["code"]?.jsonPrimitive?.intOrNull?.toLong(),
                    input = JsonBridgeMapper.encodeJsonElement(node.input) as? Map<String?, Any?>,
                )
            is FailureNode ->
                NodeMessage(
                    type = NodeType.FAILURE_NODE,
                    cause = node.cause.message ?: node.cause.toString(),
                )
            else -> NodeMessage(type = NodeType.FAILURE_NODE, cause = "Unknown node type: $node")
        }

    private fun mapCallbacks(node: ContinueNode): List<CallbackMessage> {
        val typeCounts = mutableMapOf<String, Int>()
        return node.callbacks.map { callback ->
            val type = callbackType(callback)
            val index = typeCounts.getOrDefault(type, 0)
            typeCounts[type] = index + 1
            mapCallback(callback, type, index.toLong())
        }
    }

    /**
     * The server-registered `"type"` string from [AbstractCallback.json], stable across R8/proguard
     * minification — unlike [Any.javaClass]'s `simpleName`, which is obfuscated in a minified build.
     */
    private fun callbackType(callback: Callback): String =
        (callback as AbstractCallback).json["type"]?.jsonPrimitive?.content
            ?: throw IllegalStateException("Callback is missing a \"type\" field: $callback")

    private fun mapCallback(callback: Callback, type: String, index: Long): CallbackMessage {
        var message = CallbackMessage(type = type, index = index)

        if (callback is AbstractValidatedCallback) {
            message =
                message.copy(
                    prompt = callback.prompt,
                    validateOnly = callback.validateOnly,
                    policies = JsonBridgeMapper.encodeJsonElement(callback.policies) as? Map<String?, Any?>,
                    failedPolicies =
                        callback.failedPolicies.map {
                            mapOf(
                                "params" to JsonBridgeMapper.encodeJsonElement(it.params),
                                "policyRequirement" to it.policyRequirement,
                            )
                        },
                )
        }
        if (callback is AttributeInputCallback) {
            message = message.copy(name = callback.name, required = callback.required)
        }

        return when (callback) {
            is NameCallback -> message.copy(prompt = callback.prompt, value = callback.name)
            is PasswordCallback -> message.copy(prompt = callback.prompt, value = "")
            is ValidatedUsernameCallback -> message.copy(value = callback.username)
            is ValidatedPasswordCallback -> message.copy(value = "", echoOn = callback.echoOn)
            is TextInputCallback ->
                message.copy(
                    prompt = callback.prompt,
                    defaultText = callback.defaultText,
                    value = callback.text,
                )
            is TextOutputCallback ->
                message.copy(
                    message = callback.message,
                    messageType = callback.messageType.name,
                )
            is ChoiceCallback ->
                message.copy(
                    prompt = callback.prompt,
                    choices = callback.choices,
                    defaultChoice = callback.defaultChoice.toLong(),
                    selectedIndex = callback.selectedIndex.toLong(),
                )
            is KbaCreateCallback ->
                message.copy(
                    prompt = callback.prompt,
                    predefinedQuestions = callback.predefinedQuestions,
                    selectedQuestion = callback.selectedQuestion,
                    selectedAnswer = callback.selectedAnswer,
                    allowUserDefinedQuestions = callback.allowUserDefinedQuestions,
                )
            is TermsAndConditionsCallback ->
                message.copy(
                    version = callback.version,
                    terms = callback.terms,
                    createDate = callback.createDate,
                    accepted = callback.accepted,
                )
            is BooleanAttributeInputCallback -> message.copy(value = callback.value)
            is NumberAttributeInputCallback -> message.copy(value = callback.value)
            is StringAttributeInputCallback -> message.copy(value = callback.value)
            else ->
                message.copy(
                    raw = JsonBridgeMapper.encodeJsonElement((callback as AbstractCallback).json)
                        as? Map<String?, Any?>,
                )
        }
    }
}
