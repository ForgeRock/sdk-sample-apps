/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.mapper

import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

/**
 * Converts native `kotlinx.serialization.json` values into plain Kotlin values (`Map`/`List`/
 * scalars) that Pigeon's `StandardMessageCodec` can serialize across the platform channel.
 * Trimmed to the encode direction only (this bridge only ever sends native JSON outward, never
 * decodes it back).
 */
internal object JsonBridgeMapper {
    fun encodeJsonElement(element: JsonElement): Any? =
        when (element) {
            JsonNull -> null
            is JsonPrimitive -> encodePrimitive(element)
            is JsonObject -> element.mapValues { (_, value) -> encodeJsonElement(value) }
            is JsonArray -> element.map { encodeJsonElement(it) }
        }

    private fun encodePrimitive(value: JsonPrimitive): Any? {
        if (value.isString) return value.content
        val raw = value.content
        raw.toBooleanStrictOrNull()?.let { return it }
        raw.toLongOrNull()?.let { return it }
        raw.toDoubleOrNull()?.let { return it }
        return raw
    }
}
