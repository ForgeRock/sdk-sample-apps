/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.davinci.collector.BooleanCollector
import com.pingidentity.davinci.collector.DeviceAuthenticationCollector
import com.pingidentity.davinci.collector.DeviceRegistrationCollector
import com.pingidentity.davinci.collector.FlowCollector
import com.pingidentity.davinci.collector.ImageCollector
import com.pingidentity.davinci.collector.LabelCollector
import com.pingidentity.davinci.collector.MetadataCollector
import com.pingidentity.davinci.collector.MultiSelectCollector
import com.pingidentity.davinci.collector.PasswordCollector
import com.pingidentity.davinci.collector.PhoneNumberCollector
import com.pingidentity.davinci.collector.PollingCollector
import com.pingidentity.davinci.collector.QRCodeCollector
import com.pingidentity.davinci.collector.ReadOnlyTextCollector
import com.pingidentity.davinci.collector.SingleSelectCollector
import com.pingidentity.davinci.collector.SubmitCollector
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.davinci.plugin.Collector
import com.pingidentity.network.HttpRequest
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ContinueNodeAware
import com.pingidentity.orchestrate.FlowContext
import com.pingidentity.orchestrate.SharedContext
import com.pingidentity.orchestrate.Workflow
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

/**
 * The 17 keys `davinci`'s `CollectorRegistry` registers at 2.2.0. AndroidX Startup doesn't run
 * in a JVM test, so the tests register the same table themselves.
 */
internal val coreRegistry: Map<String, () -> Collector<*>> =
    mapOf(
        "TEXT" to ::TextCollector,
        "PASSWORD" to ::PasswordCollector,
        "PASSWORD_VERIFY" to ::PasswordCollector,
        "SUBMIT_BUTTON" to ::SubmitCollector,
        "ACTION" to ::FlowCollector,
        "LABEL" to ::LabelCollector,
        "SINGLE_SELECT" to ::SingleSelectCollector,
        "MULTI_SELECT" to ::MultiSelectCollector,
        "BOOLEAN" to ::BooleanCollector,
        "DEVICE_REGISTRATION" to ::DeviceRegistrationCollector,
        "DEVICE_AUTHENTICATION" to ::DeviceAuthenticationCollector,
        "PHONE_NUMBER" to ::PhoneNumberCollector,
        "READ_ONLY_TEXT" to ::ReadOnlyTextCollector,
        "POLLING" to ::PollingCollector,
        "QR_CODE" to ::QRCodeCollector,
        "IMAGE" to ::ImageCollector,
        "METADATA" to ::MetadataCollector,
    )

/** A captured node from `example/integration_test/support/fixtures/<name>.json`. */
internal fun fixture(name: String): JsonObject {
    val text =
        requireNotNull(object {}.javaClass.getResource("/$name.json")) { "no fixture $name.json" }
            .readText()
    return Json.parseToJsonElement(text).jsonObject
}

/**
 * The collectors the SDK builds for a captured node, the way its internal `Form.parse` does:
 * `CollectorFactory.collector()`'s loop over `form.components.fields` (lookup by `inputType ?:
 * type`, unregistered fields dropped), then `formData.value` as initial values. The loop is
 * repeated here because the factory needs a `DaVinci`, which a JVM test can't build (its
 * defaults read `android.os.LocaleList`); of the core collectors only `PollingCollector`
 * is `DaVinciAware`, and nothing here reads its `davinci`.
 */
internal fun collectorsOf(node: JsonObject): List<Collector<*>> {
    val fields =
        node["form"]?.jsonObject?.get("components")?.jsonObject?.get("fields") as? JsonArray
            ?: JsonArray(emptyList())
    val collectors =
        fields.mapNotNull { element ->
            val field = element.jsonObject
            val type = field["inputType"]?.jsonPrimitive?.content ?: field["type"]?.jsonPrimitive?.content
            coreRegistry[type]?.invoke()?.init(field)
        }
    node["formData"]?.jsonObject?.get("value")?.jsonObject?.let { values ->
        collectors.forEach { collector -> values[collector.id()]?.let(collector::init) }
    }
    return collectors
}

/** The raw `form.components.fields` entries of a captured node. */
internal fun fieldsOf(node: JsonObject) =
    node["form"]!!.jsonObject["components"]!!.jsonObject["fields"]!!.jsonArray

/**
 * A [ContinueNode] over [node]'s JSON holding [collectors], injected into each
 * [ContinueNodeAware] one the way `CollectorFactory.inject` does — so a `PasswordCollector`
 * without a policy of its own falls back to the node's. A plain [Workflow] stands in for the
 * `DaVinci` a JVM test can't build; the stub is never submitted.
 */
internal fun continueNodeOf(node: JsonObject, collectors: List<Collector<*>>): ContinueNode {
    val stub =
        object : ContinueNode(FlowContext(SharedContext(mutableMapOf())), Workflow(), node, collectors) {
            override fun asRequest(): HttpRequest = error("A stub ContinueNode is never submitted")
        }
    collectors.filterIsInstance<ContinueNodeAware>().forEach { it.continueNode = stub }
    return stub
}
