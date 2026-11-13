/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.flutter.davinci.NodeType
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.FlowContext
import com.pingidentity.orchestrate.Session
import com.pingidentity.orchestrate.SharedContext
import com.pingidentity.orchestrate.SuccessNode
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * The `ContinueNode` branch isn't covered here: its page fields come from extensions that cast to
 * the SDK's internal `Connector`, which a JVM test can't build. Collector mapping is tested
 * directly, and the whole path runs in the example host's integration tests.
 */
class DaVinciNodeMapperTest {
    @Test
    fun `maps a success node`() {
        val node = SuccessNode(session = object : Session { override val value = "auth-code" })
        assertEquals(NodeType.SUCCESS_NODE, DaVinciNodeMapper.map(node).type)
    }

    @Test
    fun `maps an error node with its message, status, and input`() {
        val node =
            ErrorNode(
                context = FlowContext(SharedContext(mutableMapOf())),
                input = buildJsonObject { put("code", JsonPrimitive("invalidValue")) },
                message = "Invalid value",
                status = 400,
            )

        val message = DaVinciNodeMapper.map(node)

        assertEquals(NodeType.ERROR_NODE, message.type)
        assertEquals("Invalid value", message.message)
        assertEquals(400L, message.status)
        assertEquals(mapOf<String?, Any?>("code" to "invalidValue"), message.input)
        // No `details`, and no ContinueNode in the flow context: nothing to retry from.
        assertNull(message.errorDetails)
        assertNull(message.collectors)
    }

    @Test
    fun `decodes a registration's password-policy details, innerError included`() {
        val details = DaVinciNodeMapper.errorDetails(fixture("ssoRegisterWeakPassword"))

        val detail = details.single() as Map<*, *>
        assertEquals(400L, detail["statusCode"])
        val raw = detail["rawResponse"] as Map<*, *>
        assertEquals("INVALID_DATA", raw["code"])
        val error = (raw["details"] as List<*>).single() as Map<*, *>
        assertEquals("INVALID_VALUE", error["code"])
        assertEquals("password", error["target"])
        assertEquals("User password did not satisfy password policy requirements", error["message"])
        // `unsatisfiedRequirements` names minCharacters three times; the map holds it once.
        assertEquals(
            setOf("minCharacters", "length", "minUniqueCharacters", "excludesCommonlyUsed"),
            (error["innerError"] as Map<*, *>).keys,
        )
        assertEquals(
            "The provided password is shorter than the minimum required length of 8 characters",
            (error["innerError"] as Map<*, *>)["length"],
        )
    }

    @Test
    fun `decodes a sign-on's details, which name no field`() {
        val detail = DaVinciNodeMapper.errorDetails(fixture("ssoWrongPassword")).single() as Map<*, *>

        // A user lookup's raw response is a user search result, not a PingOne error.
        assertEquals(200L, detail["statusCode"])
        assertEquals(
            mapOf("id" to null, "code" to null, "message" to null, "details" to null),
            detail["rawResponse"],
        )
    }

    @Test
    fun `drops a malformed detail and keeps the rest, as iOS does`() {
        val input =
            Json.parseToJsonElement(
                """{"details":[
                  {"rawResponse":{"code":"NO_STATUS"}},
                  {"rawResponse":{"code":"KEPT","details":[{"target":"email","message":"Taken"}]},"statusCode":409}
                ]}""",
            ).jsonObject

        val details = DaVinciNodeMapper.errorDetails(input)

        val kept = details.single() as Map<*, *>
        assertEquals(409L, kept["statusCode"])
        val error = ((kept["rawResponse"] as Map<*, *>)["details"] as List<*>).single() as Map<*, *>
        assertEquals("email", error["target"])
        assertNull(error["innerError"])
    }

    @Test
    fun `reports fields with no registered collector, key-less ones included`() {
        val agreement = fixture("agreementForm")
        val core = coreRegistry.keys

        assertEquals(
            listOf(mapOf<String?, Any?>("key" to null, "type" to "ERROR_DISPLAY")),
            DaVinciNodeMapper.unsupportedFields(agreement, core),
        )
        // The lookup key is inputType ?: type, as in the factory: AGREEMENT resolves through
        // READ_ONLY_TEXT, so dropping that registration drops the field.
        assertEquals(
            listOf("READ_ONLY_TEXT", "ERROR_DISPLAY"),
            DaVinciNodeMapper.unsupportedFields(agreement, core - "READ_ONLY_TEXT").map { (it as Map<*, *>)["type"] },
        )
    }

    @Test
    fun `reports a field with an unregistered inputType`() {
        val input =
            Json.parseToJsonElement(
                """{"form":{"components":{"fields":[
                  {"type":"TEXT","key":"username"},
                  {"type":"TEXT","inputType":"FUTURE_FIELD","key":"future"},
                  {"type":"PROTECT","key":"protectsdk"}
                ]}}}""",
            ).jsonObject

        assertEquals(
            listOf(
                mapOf<String?, Any?>("key" to "future", "type" to "FUTURE_FIELD"),
                mapOf<String?, Any?>("key" to "protectsdk", "type" to "PROTECT"),
            ),
            DaVinciNodeMapper.unsupportedFields(input, coreRegistry.keys),
        )
    }

    @Test
    fun `a form with every field registered reports nothing`() {
        assertEquals(emptyList(), DaVinciNodeMapper.unsupportedFields(fixture("formFieldsForm"), coreRegistry.keys))
        assertEquals(emptyList(), DaVinciNodeMapper.unsupportedFields(buildJsonObject {}, coreRegistry.keys))
    }

    @Test
    fun `maps a failure node to its cause`() {
        val message = DaVinciNodeMapper.map(FailureNode(IllegalStateException("Rewind failed.")))
        assertEquals(NodeType.FAILURE_NODE, message.type)
        assertEquals("Rewind failed.", message.cause)
    }
}
