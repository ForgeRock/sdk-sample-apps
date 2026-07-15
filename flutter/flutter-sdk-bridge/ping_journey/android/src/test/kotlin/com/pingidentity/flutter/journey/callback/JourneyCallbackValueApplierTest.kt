/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.callback

import com.pingidentity.flutter.journey.CallbackValueMessage
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
import com.pingidentity.orchestrate.Action
import com.pingidentity.orchestrate.ContinueNode
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/**
 * Unit tests for [JourneyCallbackValueApplier.apply]: verifies each callback type's submitted
 * value lands on the correct native field, and that lookup/type-mismatch failures are surfaced.
 */
class JourneyCallbackValueApplierTest {

    @Test
    fun `applies String value onto NameCallback name`() {
        val callback = NameCallback()
        apply(callback, "NameCallback", value = "John Doe")

        assertEquals("John Doe", callback.name)
    }

    @Test
    fun `applies String value onto PasswordCallback password`() {
        val callback = PasswordCallback()
        apply(callback, "PasswordCallback", value = "s3cr3t")

        assertEquals("s3cr3t", callback.password)
    }

    @Test
    fun `applies String value onto ValidatedUsernameCallback username`() {
        val callback = ValidatedUsernameCallback()
        apply(callback, "ValidatedUsernameCallback", value = "jdoe")

        assertEquals("jdoe", callback.username)
    }

    @Test
    fun `applies String value onto ValidatedPasswordCallback password`() {
        val callback = ValidatedPasswordCallback()
        apply(callback, "ValidatedPasswordCallback", value = "s3cr3t")

        assertEquals("s3cr3t", callback.password)
    }

    @Test
    fun `applies String value onto TextInputCallback text`() {
        val callback = TextInputCallback()
        apply(callback, "TextInputCallback", value = "some text")

        assertEquals("some text", callback.text)
    }

    @Test
    fun `applies String value onto StringAttributeInputCallback value`() {
        val callback = StringAttributeInputCallback()
        apply(callback, "StringAttributeInputCallback", value = "user@example.com")

        assertEquals("user@example.com", callback.value)
    }

    @Test
    fun `applies numeric value onto NumberAttributeInputCallback value as Double`() {
        val callback = NumberAttributeInputCallback()
        apply(callback, "NumberAttributeInputCallback", value = 42)

        assertEquals(42.0, callback.value)
    }

    @Test
    fun `applies Boolean value onto BooleanAttributeInputCallback value`() {
        val callback = BooleanAttributeInputCallback()
        apply(callback, "BooleanAttributeInputCallback", value = true)

        assertEquals(true, callback.value)
    }

    @Test
    fun `applies numeric value onto ChoiceCallback selectedIndex`() {
        val callback = ChoiceCallback()
        apply(callback, "ChoiceCallback", value = 2)

        assertEquals(2, callback.selectedIndex)
    }

    @Test
    fun `applies Boolean value onto TermsAndConditionsCallback accepted`() {
        val callback = TermsAndConditionsCallback()
        apply(callback, "TermsAndConditionsCallback", value = true)

        assertEquals(true, callback.accepted)
    }

    @Test
    fun `applies map value onto KbaCreateCallback sub-fields`() {
        val callback = KbaCreateCallback()
        apply(
            callback,
            "KbaCreateCallback",
            value = mapOf(
                "selectedQuestion" to "Pet's name?",
                "selectedAnswer" to "Rex",
                "allowUserDefinedQuestions" to true,
            ),
        )

        assertEquals("Pet's name?", callback.selectedQuestion)
        assertEquals("Rex", callback.selectedAnswer)
        assertEquals(true, callback.allowUserDefinedQuestions)
    }

    @Test
    fun `KbaCreateCallback partial map only updates provided sub-fields`() {
        val callback = KbaCreateCallback().apply {
            selectedQuestion = "existing question"
            selectedAnswer = "existing answer"
            allowUserDefinedQuestions = true
        }

        apply(callback, "KbaCreateCallback", value = mapOf("selectedAnswer" to "new answer"))

        assertEquals("existing question", callback.selectedQuestion)
        assertEquals("new answer", callback.selectedAnswer)
        assertEquals(true, callback.allowUserDefinedQuestions)
    }

    @Test
    fun `throws for unsupported callback type such as TextOutputCallback`() {
        val callback = TextOutputCallback()
        val node = mockNode(listOf(callback))

        assertFailsWith<UnsupportedOperationException> {
            JourneyCallbackValueApplier.apply(
                node,
                listOf(CallbackValueMessage(type = "TextOutputCallback", index = 0, value = "ignored")),
            )
        }
    }

    @Test
    fun `throws IllegalArgumentException when no callback matches type and index`() {
        val node = mockNode(listOf(NameCallback()))

        val exception = assertFailsWith<IllegalArgumentException> {
            JourneyCallbackValueApplier.apply(
                node,
                listOf(CallbackValueMessage(type = "PasswordCallback", index = 0, value = "x")),
            )
        }
        assertEquals(
            "No active callback found for type PasswordCallback at index 0",
            exception.message,
        )
    }

    @Test
    fun `throws IllegalArgumentException when value type mismatches expected type`() {
        val callback = NameCallback()
        val node = mockNode(listOf(callback))

        assertFailsWith<IllegalArgumentException> {
            JourneyCallbackValueApplier.apply(
                node,
                listOf(CallbackValueMessage(type = "NameCallback", index = 0, value = 123)),
            )
        }
    }

    @Test
    fun `applies values addressed by index within same-type group`() {
        val first = NameCallback()
        val second = NameCallback()
        val node = mockNode(listOf(first, second))

        JourneyCallbackValueApplier.apply(
            node,
            listOf(CallbackValueMessage(type = "NameCallback", index = 1, value = "second value")),
        )

        assertEquals("", first.name)
        assertEquals("second value", second.name)
    }

    // --- Helpers -----------------------------------------------------------------------------

    private fun mockNode(callbacks: List<Callback>): ContinueNode {
        val node = mock(ContinueNode::class.java)
        `when`(node.actions).thenReturn(callbacks.map { it as Action })
        return node
    }

    private fun apply(callback: Callback, type: String, value: Any?) {
        val node = mockNode(listOf(callback))
        JourneyCallbackValueApplier.apply(node, listOf(CallbackValueMessage(type = type, index = 0, value = value)))
    }
}
