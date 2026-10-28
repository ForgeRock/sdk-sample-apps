/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.davinci.collector.BooleanCollector
import com.pingidentity.davinci.collector.InvalidLength
import com.pingidentity.davinci.collector.MaxRepeat
import com.pingidentity.davinci.collector.SingleValueCollector
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.davinci.plugin.Collector
import com.pingidentity.flutter.davinci.ValidationErrorKind
import com.pingidentity.flutter.davinci.ValidationErrorMessage
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

/**
 * Local validation over the captured Form Validation node: two regex-validated, required `TEXT`
 * fields and a `PASSWORD_VERIFY` whose policy is the node's, not the field's.
 *
 * The cases in [sharedCases] are repeated verbatim in the iOS `DaVinciValidationMapperTests`,
 * so the two platforms are checked against the same expected errors. Errors are compared as
 * sorted lists: iOS iterates `minCharacters` in dictionary order, which is unspecified.
 */
class DaVinciValidationMapperTest {
    private val form = fixture("formValidationForm")

    /** The form's collectors, the password reading the node's policy through a stub node. */
    private fun collectors(): List<Collector<*>> =
        collectorsOf(form).also { continueNodeOf(form, it) }

    private fun validate(username: String, email: String, password: String): List<String> {
        val collectors = collectors()
        (collectors[1] as SingleValueCollector).value = username
        (collectors[2] as SingleValueCollector).value = email
        (collectors[3] as SingleValueCollector).value = password
        return DaVinciValidationMapper.validate(collectors).map(::describe).sorted()
    }

    @Test
    fun `the shared cases produce the expected errors`() {
        sharedCases.forEach { (input, expected) ->
            val (username, email, password) = input
            assertEquals(expected.sorted(), validate(username, email, password), "for $input")
        }
    }

    @Test
    fun `labels and buttons contribute nothing`() {
        val errors = DaVinciValidationMapper.validate(collectors())
        assertEquals(setOf(1L, 2L, 3L), errors.map { it.index }.toSet())
    }

    @Test
    fun `an unbounded maximum crosses as null`() {
        val length = DaVinciValidationMapper.map(InvalidLength(8, Int.MAX_VALUE), "PASSWORD", 0)
        assertEquals(8L, length.min)
        assertNull(length.max)
        assertNull(DaVinciValidationMapper.map(MaxRepeat(Int.MAX_VALUE), "PASSWORD", 0).max)
    }

    // Pinned divergences: each asserts Android's behaviour, and the iOS test asserts iOS's. When
    // one fails after an SDK bump, the platforms have aligned; update the docs and the assertion.

    // TODO(SDKS-5537): drop the pin once the platforms agree on full vs partial regex matching.
    @Test
    fun `android matches a regex against the whole value`() {
        val field =
            Json.parseToJsonElement(
                """{"type":"TEXT","key":"code","label":"Code",
                   "validation":{"regex":"[0-9]+","errorMessage":"Digits only"}}""",
            ).jsonObject
        val collector = TextCollector().apply { init(field) }
        collector.value = "abc1"
        // iOS uses firstMatch, so "abc1" passes there.
        assertEquals(
            listOf("0:REGEX:Digits only"),
            DaVinciValidationMapper.validate(listOf(collector)).map(::describe),
        )
    }

    // TODO(SDKS-5538): drop the pin once the platforms report the same error for this box.
    @Test
    fun `android reports a required unchecked box as required`() {
        val agreement = collectorsOf(fixture("agreementForm"))
        val box = agreement.filterIsInstance<BooleanCollector>().single()
        // The captured box carries errorMessage "You must agree to the terms to continue.", which
        // iOS reports as a regex error instead.
        assertEquals(
            listOf("${agreement.indexOf(box)}:REQUIRED"),
            DaVinciValidationMapper.validate(agreement).map(::describe),
        )
    }

    // TODO(SDKS-5539): drop the pin once the platforms count password characters the same way.
    @Test
    fun `android measures a password in UTF-16 code units`() {
        // Two emoji are four code units here but two characters on iOS, so only iOS reports the
        // length: "Ab1!" plus two emoji is 8 units long (min 8) and 6 characters.
        assertEquals(emptyList(), validate("flutter", "flutter@example.com", "Ab1!😀😀"))
    }

    companion object {
        private const val UPPER = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        private const val LOWER = "abcdefghijklmnopqrstuvwxyz"
        private const val DIGITS = "0123456789"
        private const val SPECIAL = "~!@#$%^&*()-_=+[]{}|;:,.<>/?"

        /** `(username, email, password)` to the expected errors, as [describe] renders them. */
        val sharedCases: List<Pair<Triple<String, String, String>, List<String>>> =
            listOf(
                Triple("", "", "") to
                    listOf(
                        "1:REQUIRED",
                        "1:REGEX:Must be alphanumeric",
                        "2:REQUIRED",
                        "2:REGEX:Not a valid email",
                        "3:REQUIRED",
                        "3:INVALID_LENGTH:min=8:max=255",
                        "3:UNIQUE_CHARACTER:min=5",
                        "3:MIN_CHARACTERS:min=1:$UPPER",
                        "3:MIN_CHARACTERS:min=1:$LOWER",
                        "3:MIN_CHARACTERS:min=1:$DIGITS",
                        "3:MIN_CHARACTERS:min=1:$SPECIAL",
                    ),
                Triple("flutter user", "flutter@example.com", "Abcdef1!") to
                    listOf("1:REGEX:Must be alphanumeric"),
                Triple("flutter", "flutter@example.com", "aaa") to
                    listOf(
                        "3:INVALID_LENGTH:min=8:max=255",
                        "3:UNIQUE_CHARACTER:min=5",
                        "3:MAX_REPEAT:max=2",
                        "3:MIN_CHARACTERS:min=1:$UPPER",
                        "3:MIN_CHARACTERS:min=1:$DIGITS",
                        "3:MIN_CHARACTERS:min=1:$SPECIAL",
                    ),
                Triple("flutter", "flutter@example.com", "Passw0rd!") to emptyList(),
            )

        /** `index:KIND[:min=..][:max=..][:character or message]`, for readable comparisons. */
        fun describe(error: ValidationErrorMessage): String =
            buildString {
                append("${error.index}:${error.kind.name}")
                error.min?.let { append(":min=$it") }
                error.max?.let { append(":max=$it") }
                error.character?.let { append(":$it") }
                if (error.kind == ValidationErrorKind.REGEX) append(":${error.message}")
            }
    }
}
