/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.collector

import com.pingidentity.davinci.collector.BooleanCollector
import com.pingidentity.davinci.collector.Device
import com.pingidentity.davinci.collector.DeviceAuthenticationCollector
import com.pingidentity.davinci.collector.DeviceRegistrationCollector
import com.pingidentity.davinci.collector.ImageCollector
import com.pingidentity.davinci.collector.LabelCollector
import com.pingidentity.davinci.collector.MetadataCollector
import com.pingidentity.davinci.collector.MultiSelectCollector
import com.pingidentity.davinci.collector.PhoneNumberCollector
import com.pingidentity.davinci.collector.PollingCollector
import com.pingidentity.davinci.collector.QRCodeCollector
import com.pingidentity.davinci.collector.ReadOnlyTextCollector
import com.pingidentity.davinci.collector.SingleValueCollector
import com.pingidentity.davinci.plugin.Collector
import com.pingidentity.flutter.davinci.CollectorValueMessage
import com.pingidentity.flutter.davinci.mapper.collectorType
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Applies Dart-submitted [CollectorValueMessage]s onto the cached `ContinueNode`'s collectors.
 *
 * Each message is addressed by `{type, index}`: `index` into the node's collectors, with `type`
 * checked against [collectorType] so a stale or mis-addressed message fails instead of writing
 * into the wrong field. Values are type-checked strictly — a wrong type throws
 * [IllegalArgumentException] (`PingException.type == "argument"`), never a silent no-op or a
 * coercion. Every message is resolved and checked before any collector is written, so a bad value
 * leaves the node untouched.
 */
internal object DaVinciCollectorValueApplier {
    fun apply(collectors: List<Collector<*>>, values: List<CollectorValueMessage>) {
        values.map { message -> assignment(resolve(collectors, message), message) }
            .forEach { it() }
    }

    private fun resolve(collectors: List<Collector<*>>, message: CollectorValueMessage): Collector<*> {
        val collector =
            collectors.getOrNull(message.index.toInt())
                ?: throw IllegalArgumentException(
                    "No collector at index=${message.index} (the node has ${collectors.size})"
                )
        val actual = collectorType(collector)
        require(actual == message.type) {
            "Collector at index=${message.index} is $actual, not ${message.type}"
        }
        return collector
    }

    /** Checks [message]'s value for [collector] and returns the write, without performing it. */
    private fun assignment(collector: Collector<*>, message: CollectorValueMessage): () -> Unit {
        val value = message.value
        val where = "${message.type} at index=${message.index}"
        return when (collector) {
            // Before SingleValueCollector, which PollingCollector extends.
            is PollingCollector ->
                throw IllegalArgumentException("$where takes no value from the app: polling sets it")
            is MetadataCollector -> metadata(collector, where, value)
            is LabelCollector, is ReadOnlyTextCollector, is ImageCollector, is QRCodeCollector ->
                throw IllegalArgumentException("$where is display-only and takes no value")
            is SingleValueCollector -> {
                val text = value as? String ?: throw wrongType(where, "a String", value)
                return { collector.value = text }
            }
            is BooleanCollector -> {
                val flag = value as? Boolean ?: throw wrongType(where, "a bool", value)
                return { collector.value = flag }
            }
            is MultiSelectCollector -> {
                val list = value as? List<*> ?: throw wrongType(where, "a List<String>", value)
                val strings = list.map { it as? String ?: throw wrongType(where, "a List<String>", value) }
                return { collector.value = strings.toMutableList() }
            }
            is PhoneNumberCollector -> phoneNumber(collector, where, value)
            is DeviceRegistrationCollector -> {
                val device = device(collector.devices, where, value)
                return { collector.value = device }
            }
            is DeviceAuthenticationCollector -> {
                val device = device(collector.devices, where, value)
                return { collector.value = device }
            }
            else ->
                throw UnsupportedOperationException(
                    "$where (${collector::class.simpleName}) is not supported by the bridge"
                )
        }
    }

    /** `{countryCode, phoneNumber, phoneExtension}`, all optional Strings — the message's field names. */
    private fun phoneNumber(collector: PhoneNumberCollector, where: String, value: Any?): () -> Unit {
        val map = value as? Map<*, *> ?: throw wrongType(where, "a phone-number map", value)
        val unknown = map.keys - PHONE_KEYS
        require(unknown.isEmpty()) { "$where has unknown phone-number keys $unknown" }
        val parts =
            PHONE_KEYS.associateWith { key ->
                map[key]?.let { it as? String ?: throw wrongType("$where.$key", "a String", it) }
            }
        return {
            parts["countryCode"]?.let { collector.countryCode = it }
            parts["phoneNumber"]?.let { collector.phoneNumber = it }
            parts["phoneExtension"]?.let { collector.extension = it }
        }
    }

    /**
     * `{result: Map}` for `setResult`, or `{error: {code, message}}` for `setError`: exactly one
     * key. The collector builds its own payload and `actionKey` from either.
     */
    private fun metadata(collector: MetadataCollector, where: String, value: Any?): () -> Unit {
        val map = value as? Map<*, *> ?: throw wrongType(where, "a metadata result map", value)
        require(map.size == 1 && (map.containsKey("result") || map.containsKey("error"))) {
            "$where expects exactly one of {result} or {error}, got keys ${map.keys}"
        }
        map["result"]?.let { result ->
            val json = jsonElement(result, "$where.result") as? JsonObject
                ?: throw wrongType("$where.result", "a Map", result)
            return { collector.setResult(json) }
        }
        val error = map["error"] as? Map<*, *> ?: throw wrongType("$where.error", "a Map", map["error"])
        require(error.keys == setOf("code", "message")) {
            "$where.error expects keys {code, message}, got ${error.keys}"
        }
        val code = error["code"] as? String ?: throw wrongType("$where.error.code", "a String", error["code"])
        val message =
            error["message"] as? String ?: throw wrongType("$where.error.message", "a String", error["message"])
        return { collector.setError(code, message) }
    }

    /** A Pigeon-decoded value as JSON: maps need String keys, and nothing but JSON types passes. */
    private fun jsonElement(value: Any?, where: String): JsonElement =
        when (value) {
            null -> JsonNull
            is String -> JsonPrimitive(value)
            is Boolean -> JsonPrimitive(value)
            is Number -> JsonPrimitive(value)
            is List<*> -> JsonArray(value.mapIndexed { i, element -> jsonElement(element, "$where[$i]") })
            is Map<*, *> ->
                JsonObject(
                    value.entries.associate { (key, element) ->
                        val name = key as? String ?: throw wrongType("$where key", "a String", key)
                        name to jsonElement(element, "$where.$name")
                    }
                )
            else -> throw wrongType(where, "a JSON value", value)
        }

    /** A `{id?, type}` map selecting one of the collector's own devices — by id when given. */
    private fun device(devices: List<Device>, where: String, value: Any?): Device {
        val map = value as? Map<*, *> ?: throw wrongType(where, "a device map", value)
        val id = map["id"] as? String
        val type = map["type"] as? String
        require(id != null || type != null) { "$where needs a device id or type" }
        return devices.firstOrNull { if (id != null) it.id == id else it.type == type }
            ?: throw IllegalArgumentException("$where has no device with ${if (id != null) "id=$id" else "type=$type"}")
    }

    private fun wrongType(where: String, expected: String, value: Any?) =
        IllegalArgumentException("$where expects $expected, got ${value?.let { it::class.simpleName } ?: "null"}")

    private val PHONE_KEYS = setOf("countryCode", "phoneNumber", "phoneExtension")
}
