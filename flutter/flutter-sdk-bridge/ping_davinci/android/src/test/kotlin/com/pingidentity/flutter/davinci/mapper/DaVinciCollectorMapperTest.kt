/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.davinci.collector.PasswordCollector
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.flutter.davinci.CollectorMessage
import com.pingidentity.flutter.davinci.DeviceMessage
import com.pingidentity.flutter.davinci.OptionMessage
import com.pingidentity.flutter.davinci.RichContentReplacementMessage
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Every core collector class, mapped from node JSON captured from the live test tenant. */
class DaVinciCollectorMapperTest {
    private fun mapped(name: String): List<CollectorMessage> =
        fixture(name).let { DaVinciCollectorMapper.map(collectorsOf(it), it) }

    @Test
    fun `maps the form-fields form by class, keeping server types`() {
        val messages = mapped("formFieldsForm")

        assertEquals(fieldsOf(fixture("formFieldsForm")).size, messages.size)
        assertEquals(messages.indices.map { it.toLong() }, messages.map { it.index })
        assertEquals(
            listOf(
                "LABEL" to "label", "LABEL" to "label", "LABEL" to "label", "TEXT" to "text",
                "CHECKBOX" to "multiSelect", "DROPDOWN" to "singleSelect", "RADIO" to "singleSelect",
                "COMBOBOX" to "multiSelect", "PHONE_NUMBER" to "phoneNumber",
                "SINGLE_CHECKBOX" to "boolean", "FLOW_BUTTON" to "flow", "FLOW_LINK" to "flow",
                "SUBMIT_BUTTON" to "submit",
            ),
            messages.map { it.type to it.kind },
        )
    }

    @Test
    fun `maps labels with and without rich content`() {
        val (plain, translatable, linked) = mapped("formFieldsForm")

        assertEquals("", plain.key, "the first label has no key")
        assertEquals("<p><strong><em>Rich Text fields produce LABELs</em></strong></p><hr><p><br></p>", plain.content)
        assertNull(plain.richContent)
        assertEquals("Translatable Rich Text produce LABELs too!", translatable.richContent?.content)
        assertEquals(emptyList(), translatable.richContent?.replacements)
        assertEquals("rich-text", linked.id)
        assertEquals("A translatable rich text to take the user to {{link1}} and {{link2}}", linked.richContent?.content)
        assertEquals(
            listOf(
                RichContentReplacementMessage("link1", "google.com", "https://www.google.com", "link", "_self"),
                RichContentReplacementMessage("link2", "apple.com", "https://www.apple.com", "link", "_blank"),
            ),
            linked.richContent?.replacements,
        )
        assertNull(linked.value, "display-only")
    }

    @Test
    fun `maps text, selects, and their formData defaults`() {
        val messages = mapped("formFieldsForm")
        val text = messages[3]
        val checkbox = messages[4]
        val dropdown = messages[5]
        val radio = messages[6]
        val combobox = messages[7]

        assertEquals("text-input-key", text.id)
        assertEquals("Text Input Label", text.label)
        assertEquals(true, text.required)
        assertEquals("default text", text.value)
        assertNull(text.validationRegex)

        assertEquals(listOf("option1 value", "option2 value"), checkbox.value)
        assertEquals(
            listOf(OptionMessage("option1 label", "option1 value"), OptionMessage("option2 label", "option2 value")),
            checkbox.options,
        )
        assertEquals(listOf("option1 value", "option3 value"), combobox.value)
        assertEquals("dropdown-option2-value", dropdown.value)
        assertEquals(3, dropdown.options?.size)
        assertEquals("option2 value", radio.value)
        assertEquals("radio-group-key", radio.key)
    }

    @Test
    fun `maps the phone number into its three fields`() {
        val phone = mapped("formFieldsForm")[8]

        assertEquals("phone-field", phone.id)
        assertEquals("BF", phone.defaultCountryCode)
        assertEquals(true, phone.validatePhoneNumber)
        assertEquals(true, phone.showExtension)
        assertEquals("Extension", phone.extensionLabel, "restored after the formData default wiped it")
        assertEquals("GB", phone.countryCode)
        assertEquals("(555)555-1234", phone.phoneNumber)
        assertEquals("4321", phone.phoneExtension)
        assertNull(phone.value)
    }

    @Test
    fun `maps the boolean with its appearance and rich content`() {
        val boolean = mapped("formFieldsForm")[9]

        assertEquals("single-checkbox-field", boolean.id)
        assertEquals(false, boolean.value)
        assertEquals("SWITCH", boolean.appearance)
        assertEquals("Select the checkbox to continue.", boolean.errorMessage)
        assertEquals("I agree to the {{link1}}", boolean.richContent?.content)
        assertEquals("https://www.pingidentity.com", boolean.richContent?.replacements?.single()?.href)
    }

    @Test
    fun `maps buttons with an empty value until one is chosen`() {
        val messages = mapped("formFieldsForm")

        assertEquals(listOf("flow-button-field", "flow-link-field", "submit"), messages.takeLast(3).map { it.id })
        assertEquals(listOf("Flow Button", "Flow Link", "Submit"), messages.takeLast(3).map { it.label })
        assertEquals(listOf("", "", ""), messages.takeLast(3).map { it.value })
    }

    @Test
    fun `maps text validation and the verify-password policy`() {
        val (_, username, email, password) = mapped("formValidationForm")

        assertEquals("^[a-zA-Z0-9]+$", username.validationRegex)
        assertEquals("Must be alphanumeric", username.validationErrorMessage)
        assertEquals("^[^@]+@[^@]+\\.[^@]+$", email.validationRegex)
        assertEquals("PASSWORD_VERIFY" to "password", password.type to password.kind)
        assertNull(password.value, "passwords never cross the bridge, formData default included")
        val policy = password.passwordPolicy!!
        assertEquals(8L, policy.lengthMin)
        assertEquals(255L, policy.lengthMax)
        assertEquals(5L, policy.minUniqueCharacters)
        assertEquals(2L, policy.maxRepeatedCharacters)
        assertEquals(
            mapOf<String?, Long?>(
                "~!@#$%^&*()-_=+[]{}|;:,.<>/?" to 1L,
                "0123456789" to 1L,
                "ABCDEFGHIJKLMNOPQRSTUVWXYZ" to 1L,
                "abcdefghijklmnopqrstuvwxyz" to 1L,
            ),
            policy.minCharacters,
        )
    }

    @Test
    fun `maps an unbounded policy and an empty regex to null`() {
        val password =
            PasswordCollector().init(
                Json.parseToJsonElement("""{"type":"PASSWORD","key":"p","passwordPolicy":{"name":"Open"}}""").jsonObject,
            )
        val text =
            TextCollector().init(
                Json.parseToJsonElement("""{"type":"TEXT","key":"t","validation":{"regex":"","errorMessage":"x"}}""").jsonObject,
            )

        val (passwordMessage, textMessage) = DaVinciCollectorMapper.map(listOf(password, text))

        val policy = passwordMessage.passwordPolicy!!
        assertEquals(0L, policy.lengthMin)
        assertNull(policy.lengthMax)
        assertNull(policy.maxRepeatedCharacters)
        assertEquals(emptyMap(), policy.minCharacters)
        assertNull(textMessage.validationRegex)
        assertNull(textMessage.validationErrorMessage)
    }

    @Test
    fun `a password with no policy anywhere maps none`() {
        val sso = mapped("ssoMenu")

        assertEquals(listOf("text", "password", "submit", "flow", "flow"), sso.map { it.kind })
        assertNull(sso[1].passwordPolicy)
    }

    @Test
    fun `maps the agreement read-only text`() {
        val agreement = mapped("agreementForm").first()

        assertEquals("AGREEMENT" to "readOnlyText", agreement.type to agreement.kind)
        assertEquals("agreement", agreement.id)
        assertEquals("This is example agreement text, you can edit this text in the agreements section.", agreement.content)
        assertEquals("Terms of Service Agreement", agreement.title)
        assertEquals(true, agreement.titleEnabled)
        assertEquals(true, agreement.enabled)
        assertEquals("1c3de4cc-74c0-4a42-b484-4047b10122ce", agreement.agreementId)
        assertEquals(false, agreement.useDynamicAgreement)
        assertNull(agreement.value)
    }

    @Test
    fun `maps the image`() {
        val image = mapped("imageForm").single { it.kind == "image" }

        assertEquals("IMAGE", image.type)
        assertEquals("image", image.id)
        assertEquals("Image Collector Test", image.imageDescription)
        assertEquals(
            "https://img.magnific.com/free-photo/closeup-shot-beautiful-butterfly-with-interesting-textures-orange-petaled-flower_181624-7640.jpg",
            image.imageUrl,
        )
        assertEquals("https://www.pingidentity.com/en.html", image.hyperlinkUrl)
        assertNull(image.value)
    }

    @Test
    fun `maps the QR code as its data URI, never decoded`() {
        val form = fixture("qrCodeForm")
        val qrCode = mapped("qrCodeForm").single { it.kind == "qrCode" }
        val field = fieldsOf(form).single { it.jsonObject["type"]?.jsonPrimitive?.content == "QR_CODE" }.jsonObject

        assertEquals("QR_CODE", qrCode.type)
        assertEquals("qr-code", qrCode.id, "2.2.0: id() is the key, not a random UUID")
        assertEquals("qr-code", qrCode.key)
        assertEquals(field["content"]?.jsonPrimitive?.content, qrCode.content)
        assertTrue(qrCode.content!!.startsWith("data:image/png;base64,"))
        assertEquals(
            "If you can't scan the QR code, use the following link:https://www.pingidentity.com/en.html",
            qrCode.fallbackText,
        )
        assertNull(qrCode.value)
    }

    @Test
    fun `maps simple and challenge polling`() {
        val simple = mapped("pollingContinueForm").single { it.kind == "polling" }
        val challenge = mapped("pollingChallengeForm").single { it.kind == "polling" }

        assertEquals("POLLING", simple.type)
        assertEquals("polling-field", simple.id)
        assertEquals(2000L, simple.pollIntervalMillis)
        assertEquals(3L, simple.pollRetries)
        assertEquals(3L, simple.retriesAllowed)
        assertEquals(false, simple.pollChallengeStatus)
        assertNull(simple.challenge)
        assertNull(simple.value, "polling sets its own value")

        assertEquals(true, challenge.pollChallengeStatus)
        assertEquals(
            fieldsOf(fixture("pollingChallengeForm"))
                .single { it.jsonObject["type"]?.jsonPrimitive?.content == "POLLING" }
                .jsonObject["challenge"]?.jsonPrimitive?.content,
            challenge.challenge,
        )
    }

    @Test
    fun `maps registration devices, which have no id`() {
        val registration = mapped("deviceRegistrationForm").single()

        assertEquals("DEVICE_REGISTRATION" to "deviceRegistration", registration.type to registration.kind)
        assertEquals("device-registration", registration.key)
        assertEquals(true, registration.required)
        assertEquals(listOf("EMAIL", "SMS", "VOICE"), registration.devices?.map { it?.type })
        assertEquals(
            DeviceMessage(
                id = null,
                type = "EMAIL",
                title = "Email",
                deviceDescription = "Receive an authentication passcode in your email.",
                iconSrc = "https://assets.pingone.com/ux/end-user/2.10.0/images/icon-outline-mail.svg",
                isDefault = false,
            ),
            registration.devices?.first(),
        )
        assertNull(registration.value, "no device chosen yet")
    }

    @Test
    fun `maps authentication devices with their ids and default`() {
        val authentication = mapped("deviceAuthenticationForm").single()

        assertEquals("deviceAuthentication", authentication.kind)
        assertEquals(
            listOf("fixture-device-1" to true, "fixture-device-2" to false, "fixture-device-3" to false),
            authentication.devices?.map { it?.id to it?.isDefault },
        )
        assertNull(authentication.value)
    }

    @Test
    fun `maps the metadata payload`() {
        val metadata = mapped("metadataForm").single()

        assertEquals("METADATA" to "metadata", metadata.type to metadata.kind)
        assertEquals("sdkMetadata", metadata.key)
        assertEquals(mapOf<String?, Any?>("testkey" to "testValue"), metadata.metadata)
        assertNull(metadata.value, "no result set yet")
    }
}
