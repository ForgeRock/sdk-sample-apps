/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.mapper

import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * Unit tests for [JsonBridgeMapper.encodeJsonElement], covering every `JsonElement` subtype and a
 * representative nested shape.
 */
class JsonBridgeMapperTest {

    @Test
    fun `encodeJsonElement maps JsonNull to null`() {
        assertNull(JsonBridgeMapper.encodeJsonElement(JsonNull))
    }

    @Test
    fun `encodeJsonElement maps a string JsonPrimitive to a String`() {
        val result = JsonBridgeMapper.encodeJsonElement(JsonPrimitive("hello"))

        assertEquals("hello", result)
    }

    @Test
    fun `encodeJsonElement maps a boolean JsonPrimitive to a Boolean`() {
        val result = JsonBridgeMapper.encodeJsonElement(JsonPrimitive(true))

        assertEquals(true, result)
    }

    @Test
    fun `encodeJsonElement maps an integral JsonPrimitive to a Long`() {
        val result = JsonBridgeMapper.encodeJsonElement(JsonPrimitive(42))

        assertEquals(42L, result)
    }

    @Test
    fun `encodeJsonElement maps a fractional JsonPrimitive to a Double`() {
        val result = JsonBridgeMapper.encodeJsonElement(JsonPrimitive(3.14))

        assertEquals(3.14, result)
    }

    @Test
    fun `encodeJsonElement maps a JsonObject to a Map with recursively-encoded values`() {
        val jsonObject = buildJsonObject {
            put("name", JsonPrimitive("Alice"))
            put("age", JsonPrimitive(30))
            put("verified", JsonPrimitive(true))
        }

        val result = JsonBridgeMapper.encodeJsonElement(jsonObject)

        assertEquals(mapOf("name" to "Alice", "age" to 30L, "verified" to true), result)
    }

    @Test
    fun `encodeJsonElement maps a JsonArray to a List with recursively-encoded elements`() {
        val jsonArray = buildJsonArray {
            add(JsonPrimitive("a"))
            add(JsonPrimitive(1))
            add(JsonNull)
        }

        val result = JsonBridgeMapper.encodeJsonElement(jsonArray)

        assertEquals(listOf("a", 1L, null), result)
    }

    @Test
    fun `encodeJsonElement recursively encodes an object nested inside an array nested inside an object`() {
        val nested = buildJsonObject {
            put(
                "items",
                buildJsonArray {
                    add(
                        buildJsonObject {
                            put("id", JsonPrimitive(1))
                        },
                    )
                },
            )
        }

        val result = JsonBridgeMapper.encodeJsonElement(nested)

        assertEquals(mapOf("items" to listOf(mapOf("id" to 1L))), result)
    }
}
