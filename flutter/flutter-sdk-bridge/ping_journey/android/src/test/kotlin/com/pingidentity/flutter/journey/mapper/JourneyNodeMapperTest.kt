/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.mapper

import com.pingidentity.flutter.journey.NodeType
import com.pingidentity.journey.callback.ChoiceCallback
import com.pingidentity.journey.callback.KbaCreateCallback
import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.journey.callback.PasswordCallback
import com.pingidentity.journey.callback.StringAttributeInputCallback
import com.pingidentity.journey.callback.TextOutputCallback
import com.pingidentity.journey.callback.ValidatedUsernameCallback
import com.pingidentity.journey.plugin.Callback
import com.pingidentity.orchestrate.Action
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.FlowContext
import com.pingidentity.orchestrate.Node
import com.pingidentity.orchestrate.SharedContext
import com.pingidentity.orchestrate.SuccessNode
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import org.mockito.Mockito.mock
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * Unit tests for [JourneyNodeMapper]: one test per [Node] subtype, plus per-callback-type field
 * mapping for a representative set of the v1 callback set.
 */
class JourneyNodeMapperTest {

    // --- Node subtype mapping ---------------------------------------------------------------

    @Test
    fun `map SuccessNode returns SUCCESS_NODE type`() {
        val node = SuccessNode(session = com.pingidentity.orchestrate.EmptySession)

        val result = JourneyNodeMapper.map(node)

        assertEquals(NodeType.SUCCESS_NODE, result.type)
    }

    @Test
    fun `map ErrorNode returns ERROR_NODE type with message`() {
        val flowContext = FlowContext(SharedContext(mutableMapOf()))
        val node = ErrorNode(context = flowContext, message = "Something went wrong")

        val result = JourneyNodeMapper.map(node)

        assertEquals(NodeType.ERROR_NODE, result.type)
        assertEquals("Something went wrong", result.message)
    }

    @Test
    fun `map FailureNode returns FAILURE_NODE type with cause message`() {
        val node = FailureNode(cause = IllegalStateException("bad state"))

        val result = JourneyNodeMapper.map(node)

        assertEquals(NodeType.FAILURE_NODE, result.type)
        assertEquals("bad state", result.cause)
    }

    @Test
    fun `map FailureNode falls back to toString when cause has no message`() {
        val cause = RuntimeException()
        val node = FailureNode(cause = cause)

        val result = JourneyNodeMapper.map(node)

        assertEquals(NodeType.FAILURE_NODE, result.type)
        assertEquals(cause.toString(), result.cause)
    }

    // Note: `JourneyNodeMapper.map`'s `else` branch (unknown node type -> FAILURE_NODE with a
    // descriptive cause) is not covered here. `com.pingidentity.orchestrate.Node` is a Kotlin
    // sealed interface compiled with a JVM-level `PermittedSubclasses` attribute restricted to
    // ContinueNode/SuccessNode/ErrorNode/FailureNode (confirmed by the Kotlin compiler's own
    // "'when' is exhaustive so 'else' is redundant here" warning on this file, and by two
    // independent failed attempts to reach it from this test: Mockito's inline mock maker refuses
    // to mock the interface ("Unsupported settings with this type"), and the Kotlin compiler
    // rejects an anonymous object implementing it ("Anonymous object cannot extend a sealed
    // interface"). The branch is unreachable dead code from outside the `orchestrate` module.

    @Test
    fun `map ContinueNode exposes header, description, stage and callbacks`() {
        val nameCallback = NameCallback()
        val node = mockContinueNode(
            input = buildJsonObject {
                put("header", "Welcome")
                put("description", "Please sign in")
                put("stage", "Login")
            },
            actions = listOf(nameCallback),
        )

        val result = JourneyNodeMapper.map(node)

        assertEquals(NodeType.CONTINUE_NODE, result.type)
        assertEquals("Welcome", result.header)
        assertEquals("Please sign in", result.pageDescription)
        assertEquals("Login", result.stage)
        assertEquals(1, result.callbacks?.size)
    }

    @Test
    fun `map ContinueNode with no page metadata defaults to empty strings`() {
        val node = mockContinueNode(input = buildJsonObject {}, actions = emptyList())

        val result = JourneyNodeMapper.map(node)

        assertEquals("", result.header)
        assertEquals("", result.pageDescription)
        assertEquals("", result.stage)
        assertEquals(0, result.callbacks?.size)
    }

    // --- Callback field mapping (mapCallback, exercised via map(ContinueNode)) --------------

    @Test
    fun `mapCallback maps NameCallback prompt and value`() {
        val callback = NameCallback().apply { init(outputOnly("prompt" to "Enter your name")) }
        callback.name = "John Doe"

        val message = mapSingleCallback(callback)

        assertEquals("NameCallback", message.type)
        assertEquals(0L, message.index)
        assertEquals("Enter your name", message.prompt)
        assertEquals("John Doe", message.value)
    }

    @Test
    fun `mapCallback maps PasswordCallback prompt but never leaks the password value`() {
        val callback = PasswordCallback().apply { init(outputOnly("prompt" to "Enter your password")) }
        callback.password = "super-secret"

        val message = mapSingleCallback(callback)

        assertEquals("PasswordCallback", message.type)
        assertEquals("Enter your password", message.prompt)
        assertEquals("", message.value)
    }

    @Test
    fun `mapCallback maps ValidatedUsernameCallback username as value`() {
        val callback = ValidatedUsernameCallback()
        callback.username = "jdoe"

        val message = mapSingleCallback(callback)

        assertEquals("ValidatedUsernameCallback", message.type)
        assertEquals("jdoe", message.value)
    }

    @Test
    fun `mapCallback maps TextOutputCallback message and messageType`() {
        val callback = TextOutputCallback().apply {
            init(
                buildJsonObject {
                    put(
                        "output",
                        buildJsonArray {
                            add(buildJsonObject { put("name", "messageType"); put("value", 0) })
                            add(buildJsonObject { put("name", "message"); put("value", "Hello!") })
                        },
                    )
                },
            )
        }

        val message = mapSingleCallback(callback)

        assertEquals("TextOutputCallback", message.type)
        assertEquals("Hello!", message.message)
        assertEquals("INFORMATION", message.messageType)
    }

    @Test
    fun `mapCallback maps ChoiceCallback prompt, choices, defaultChoice and selectedIndex`() {
        val callback = ChoiceCallback().apply {
            init(
                buildJsonObject {
                    put(
                        "output",
                        buildJsonArray {
                            add(buildJsonObject { put("name", "prompt"); put("value", "Pick one") })
                            add(buildJsonObject { put("name", "defaultChoice"); put("value", 1) })
                            add(
                                buildJsonObject {
                                    put("name", "choices")
                                    put(
                                        "value",
                                        buildJsonArray {
                                            add(JsonPrimitive("A"))
                                            add(JsonPrimitive("B"))
                                        },
                                    )
                                },
                            )
                        },
                    )
                },
            )
        }
        callback.selectedIndex = 1

        val message = mapSingleCallback(callback)

        assertEquals("ChoiceCallback", message.type)
        assertEquals("Pick one", message.prompt)
        assertEquals(listOf("A", "B"), message.choices)
        assertEquals(1L, message.defaultChoice)
        assertEquals(1L, message.selectedIndex)
    }

    @Test
    fun `mapCallback maps KbaCreateCallback question and answer fields`() {
        val callback = KbaCreateCallback().apply {
            init(
                buildJsonObject {
                    put(
                        "output",
                        buildJsonArray {
                            add(buildJsonObject { put("name", "prompt"); put("value", "Security question") })
                            add(
                                buildJsonObject {
                                    put("name", "predefinedQuestions")
                                    put(
                                        "value",
                                        buildJsonArray {
                                            add(JsonPrimitive("Pet's name?"))
                                            add(JsonPrimitive("First school?"))
                                        },
                                    )
                                },
                            )
                            add(buildJsonObject { put("name", "allowUserDefinedQuestions"); put("value", true) })
                        },
                    )
                },
            )
        }
        callback.selectedQuestion = "Pet's name?"
        callback.selectedAnswer = "Rex"

        val message = mapSingleCallback(callback)

        assertEquals("KbaCreateCallback", message.type)
        assertEquals("Security question", message.prompt)
        assertEquals(listOf("Pet's name?", "First school?"), message.predefinedQuestions)
        assertEquals("Pet's name?", message.selectedQuestion)
        assertEquals("Rex", message.selectedAnswer)
        assertEquals(true, message.allowUserDefinedQuestions)
    }

    @Test
    fun `mapCallback maps StringAttributeInputCallback name, required and value`() {
        val callback = StringAttributeInputCallback().apply {
            init(
                buildJsonObject {
                    put(
                        "output",
                        buildJsonArray {
                            add(buildJsonObject { put("name", "name"); put("value", "mail") })
                            add(buildJsonObject { put("name", "prompt"); put("value", "Email address") })
                            add(buildJsonObject { put("name", "required"); put("value", true) })
                        },
                    )
                },
            )
        }
        callback.value = "user@example.com"

        val message = mapSingleCallback(callback)

        assertEquals("StringAttributeInputCallback", message.type)
        assertEquals("mail", message.name)
        assertEquals("Email address", message.prompt)
        assertEquals(true, message.required)
        assertEquals("user@example.com", message.value)
    }

    @Test
    fun `mapCallbacks assigns per-type indices independently`() {
        val name1 = NameCallback()
        val name2 = NameCallback()
        val password = PasswordCallback()
        val node = mockContinueNode(input = buildJsonObject {}, actions = listOf(name1, password, name2))

        val result = JourneyNodeMapper.map(node)
        val callbacks = requireNotNull(result.callbacks)

        assertEquals(3, callbacks.size)
        assertEquals("NameCallback", callbacks[0]!!.type)
        assertEquals(0L, callbacks[0]!!.index)
        assertEquals("PasswordCallback", callbacks[1]!!.type)
        assertEquals(0L, callbacks[1]!!.index)
        assertEquals("NameCallback", callbacks[2]!!.type)
        assertEquals(1L, callbacks[2]!!.index)
    }

    // --- Helpers -----------------------------------------------------------------------------

    private fun mockContinueNode(
        input: kotlinx.serialization.json.JsonObject,
        actions: List<Callback>,
    ): ContinueNode {
        val node = mock(ContinueNode::class.java)
        `when`(node.input).thenReturn(input)
        `when`(node.actions).thenReturn(actions.map { it as Action })
        return node
    }

    private fun mapSingleCallback(callback: Callback) =
        JourneyNodeMapper.map(mockContinueNode(buildJsonObject {}, listOf(callback))).callbacks!!.single()!!

    private fun outputOnly(vararg entries: Pair<String, String>) =
        buildJsonObject {
            put(
                "output",
                buildJsonArray {
                    entries.forEach { (name, value) ->
                        add(buildJsonObject { put("name", name); put("value", value) })
                    }
                },
            )
        }
}
