/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.collector

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
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.davinci.plugin.Collector
import com.pingidentity.flutter.davinci.CollectorValueMessage
import com.pingidentity.flutter.davinci.mapper.collectorsOf
import com.pingidentity.flutter.davinci.mapper.fixture
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

private fun json(text: String) = Json.parseToJsonElement(text).jsonObject

/** A realistic form: the collector order is what `{type, index}` addresses. */
private fun form(): List<Collector<*>> =
    listOf(
        LabelCollector().init(json("""{"type":"LABEL","content":"Welcome"}""")),
        TextCollector().init(json("""{"type":"TEXT","key":"username","label":"Username","required":true}""")),
        PasswordCollector().init(json("""{"type":"PASSWORD","key":"password","label":"Password"}""")),
        BooleanCollector().init(json("""{"type":"SINGLE_CHECKBOX","inputType":"BOOLEAN","key":"accept","label":"Accept"}""")),
        MultiSelectCollector().init(
            json(
                """{"type":"CHECKBOX","inputType":"MULTI_SELECT","key":"colors","label":"Colors",
                    "options":[{"label":"Red","value":"red"},{"label":"Blue","value":"blue"}]}"""
            )
        ),
        PhoneNumberCollector().init(json("""{"type":"PHONE_NUMBER","key":"phone","label":"Phone"}""")),
        DeviceRegistrationCollector().init(
            json(
                """{"type":"DEVICE_REGISTRATION","key":"device","label":"Device",
                    "options":[{"type":"EMAIL","title":"Email"},{"type":"SMS","title":"Text"}]}"""
            )
        ),
        FlowCollector().init(json("""{"type":"FLOW_BUTTON","inputType":"ACTION","key":"REGISTER","label":"Register"}""")),
    )

private fun value(type: String, index: Long, value: Any?) = CollectorValueMessage(type, index, value)

class DaVinciCollectorValueApplierTest {
    @Test
    fun `applies a value of the right type to every value-bearing collector`() {
        val collectors = form()

        DaVinciCollectorValueApplier.apply(
            collectors,
            listOf(
                value("TEXT", 1, "alice"),
                value("PASSWORD", 2, "s3cret"),
                value("SINGLE_CHECKBOX", 3, true),
                value("CHECKBOX", 4, listOf("red", "blue")),
                value("PHONE_NUMBER", 5, mapOf("countryCode" to "+1", "phoneNumber" to "5551234")),
                value("DEVICE_REGISTRATION", 6, mapOf("type" to "SMS")),
                value("FLOW_BUTTON", 7, "REGISTER"),
            ),
        )

        assertEquals("alice", (collectors[1] as TextCollector).value)
        assertEquals("s3cret", (collectors[2] as PasswordCollector).value)
        assertTrue((collectors[3] as BooleanCollector).value)
        assertEquals(listOf("red", "blue"), (collectors[4] as MultiSelectCollector).value)
        val phone = collectors[5] as PhoneNumberCollector
        assertEquals("+1", phone.countryCode)
        assertEquals("5551234", phone.phoneNumber)
        assertEquals("SMS", (collectors[6] as DeviceRegistrationCollector).value?.type)
        assertEquals("REGISTER", (collectors[7] as FlowCollector).value)
    }

    @Test
    fun `rejects a wrong-typed value with an argument error`() {
        val cases =
            listOf(
                value("TEXT", 1, 42L),
                value("SINGLE_CHECKBOX", 3, "true"),
                value("CHECKBOX", 4, "red"),
                value("CHECKBOX", 4, listOf("red", 1L)),
                value("PHONE_NUMBER", 5, "5551234"),
                value("PHONE_NUMBER", 5, mapOf("extension" to "12")),
                value("DEVICE_REGISTRATION", 6, mapOf("type" to "VOICE")),
                value("TEXT", 1, null),
            )
        cases.forEach { message ->
            assertFailsWith<IllegalArgumentException>("$message") {
                DaVinciCollectorValueApplier.apply(form(), listOf(message))
            }
        }
    }

    @Test
    fun `rejects a mis-addressed message`() {
        val error =
            assertFailsWith<IllegalArgumentException> {
                DaVinciCollectorValueApplier.apply(form(), listOf(value("PASSWORD", 1, "x")))
            }
        assertEquals("Collector at index=1 is TEXT, not PASSWORD", error.message)
        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(form(), listOf(value("TEXT", 99, "x")))
        }
    }

    @Test
    fun `rejects a value for a display-only collector`() {
        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(form(), listOf(value("LABEL", 0, "x")))
        }
        // Captured agreement and image forms: READ_ONLY_TEXT (server type AGREEMENT) and IMAGE.
        val agreement = collectorsOf(fixture("agreementForm"))
        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(agreement, listOf(value("AGREEMENT", 0, "x")))
        }
        val image = collectorsOf(fixture("imageForm"))
        val imageIndex = image.indexOfFirst { it is ImageCollector }.toLong()
        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(image, listOf(value("IMAGE", imageIndex, "x")))
        }
    }

    @Test
    fun `a bad value anywhere leaves every collector untouched`() {
        val collectors = form()

        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(
                collectors,
                listOf(value("TEXT", 1, "alice"), value("SINGLE_CHECKBOX", 3, "yes")),
            )
        }

        assertEquals("", (collectors[1] as TextCollector).value)
        assertNull((collectors[6] as DeviceRegistrationCollector).value)
    }

    @Test
    fun `sets a metadata result or error, which the collector turns into its payload`() {
        val result = collectorsOf(fixture("metadataForm"))
        val metadata = result.single() as MetadataCollector
        assertEquals(1, metadata.validate().size, "Required until a result or error is set")

        DaVinciCollectorValueApplier.apply(
            result,
            listOf(
                value(
                    "METADATA",
                    0,
                    mapOf("result" to mapOf("ok" to true, "count" to 2L, "tags" to listOf("a", null))),
                ),
            ),
        )
        assertEquals<Any?>(
            Json.parseToJsonElement("""{"ok":true,"count":2,"tags":["a",null]}"""),
            metadata.payload(),
        )
        assertEquals("sdkMetadata", metadata.actionKey)
        assertEquals(emptyList<Any>(), metadata.validate())

        val error = collectorsOf(fixture("metadataForm"))
        DaVinciCollectorValueApplier.apply(
            error,
            listOf(value("METADATA", 0, mapOf("error" to mapOf("code" to "USER_CANCELLED", "message" to "No")))),
        )
        assertEquals(
            buildJsonObject {
                put("error", buildJsonObject {
                    put("code", "USER_CANCELLED")
                    put("message", "No")
                })
            },
            (error.single() as MetadataCollector).payload(),
        )
    }

    @Test
    fun `rejects a malformed metadata value`() {
        val cases =
            listOf(
                "not a map",
                emptyMap<String, Any?>(),
                mapOf("result" to mapOf("a" to 1L), "error" to mapOf("code" to "c", "message" to "m")),
                mapOf("result" to listOf(1L)),
                mapOf("result" to mapOf(1L to "non-string key")),
                mapOf("error" to mapOf("code" to "c")),
                mapOf("error" to mapOf("code" to 1L, "message" to "m")),
                mapOf("other" to mapOf<String, Any?>()),
            )
        cases.forEach { bad ->
            val collectors = collectorsOf(fixture("metadataForm"))
            assertFailsWith<IllegalArgumentException>("$bad") {
                DaVinciCollectorValueApplier.apply(collectors, listOf(value("METADATA", 0, bad)))
            }
            assertNull((collectors.single() as MetadataCollector).payload())
        }
    }

    @Test
    fun `selects an authentication device by id, so its payload is the SDK's own`() {
        val collectors = collectorsOf(fixture("deviceAuthenticationForm"))

        DaVinciCollectorValueApplier.apply(
            collectors,
            listOf(value("DEVICE_AUTHENTICATION", 0, mapOf("id" to "fixture-device-2", "type" to "SMS"))),
        )

        val device = (collectors.single() as DeviceAuthenticationCollector)
        assertEquals("fixture-device-2", device.value?.id)
        assertEquals(JsonPrimitive("SMS"), device.payload()?.get("type"))
        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(
                collectors,
                listOf(value("DEVICE_AUTHENTICATION", 0, mapOf("id" to "no-such-device"))),
            )
        }
    }

    @Test
    fun `rejects a value for polling and the QR code`() {
        val collectors = collectorsOf(fixture("pollingQrCodeForm"))
        val qrCode = collectors.indexOfFirst { it is QRCodeCollector }.toLong()
        val polling = collectors.indexOfFirst { it is PollingCollector }.toLong()

        assertFailsWith<IllegalArgumentException> {
            DaVinciCollectorValueApplier.apply(collectors, listOf(value("QR_CODE", qrCode, "x")))
        }
        val error =
            assertFailsWith<IllegalArgumentException> {
                DaVinciCollectorValueApplier.apply(collectors, listOf(value("POLLING", polling, "continue")))
            }
        assertEquals("POLLING at index=$polling takes no value from the app: polling sets it", error.message)
    }
}
