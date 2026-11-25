/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.journey.callback.NameCallback
import com.pingidentity.journey.callback.PasswordCallback
import com.pingidentity.journey.plugin.AbstractCallback
import com.pingidentity.journey.plugin.Callback
import com.pingidentity.orchestrate.Action
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.EmptySession
import com.pingidentity.orchestrate.SuccessNode
import java.util.concurrent.CopyOnWriteArrayList
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import org.mockito.Mockito.mock
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue

/**
 * Unit tests for [ActiveNodeState]: callback lookup by `{type, index}`, node replacement and
 * clearing, and that [ActiveNodeState.withItem], [ActiveNodeState.withLock],
 * [ActiveNodeState.clear] and [ActiveNodeState.startWith] all exclude each other, and that
 * entering the lock again from inside it throws instead of deadlocking.
 */
class ActiveNodeStateTest {

    private fun <T : Callback> T.withType(type: String): T {
        (this as AbstractCallback).init(buildJsonObject { put("type", type) })
        return this
    }

    private fun mockNode(vararg callbacks: Callback): ContinueNode {
        val node = mock(ContinueNode::class.java)
        `when`(node.actions).thenReturn(callbacks.map { it as Action })
        return node
    }

    @Test
    fun `withItem returns the callback at the requested type and index`() = runBlocking {
        val firstName = NameCallback().withType("NameCallback")
        val password = PasswordCallback().withType("PasswordCallback")
        val secondName = NameCallback().withType("NameCallback")
        val state = ActiveNodeState().apply { set(mockNode(firstName, password, secondName)) }

        val first = state.withItem("NameCallback", 0) { it }
        val second = state.withItem("NameCallback", 1) { it }
        val pw = state.withItem("PasswordCallback", 0) { it }

        assertSame(firstName, first)
        assertSame(secondName, second)
        assertSame(password, pw)
    }

    @Test
    fun `withItem returns the block's result`() = runBlocking {
        val state = ActiveNodeState().apply {
            set(mockNode(NameCallback().withType("NameCallback")))
        }

        assertEquals("done", state.withItem("NameCallback", 0) { "done" })
    }

    @Test
    fun `withItem throws IllegalStateException when there is no node`() {
        val state = ActiveNodeState()

        assertFailsWith<IllegalStateException> {
            runBlocking { state.withItem("NameCallback", 0) { it } }
        }
    }

    @Test
    fun `withItem throws IllegalArgumentException for an unknown type or out of range index`() {
        val state = ActiveNodeState().apply {
            set(mockNode(NameCallback().withType("NameCallback")))
        }

        assertFailsWith<IllegalArgumentException> {
            runBlocking { state.withItem("PasswordCallback", 0) { it } }
        }
        assertFailsWith<IllegalArgumentException> {
            runBlocking { state.withItem("NameCallback", 1) { it } }
        }
    }

    @Test
    fun `set replaces the node so lookups see the new one`() = runBlocking {
        val oldCallback = NameCallback().withType("NameCallback")
        val newCallback = NameCallback().withType("NameCallback")
        val state = ActiveNodeState()

        state.set(mockNode(oldCallback))
        state.set(mockNode(newCallback))

        assertSame(newCallback, state.withItem("NameCallback", 0) { it })
    }

    @Test
    fun `set with a terminal node leaves nothing cached`() {
        val state = ActiveNodeState().apply { set(mockNode(NameCallback().withType("NameCallback"))) }

        state.set(SuccessNode(session = EmptySession))

        assertNull(state.current)
    }

    @Test
    fun `clear closes the node and drops it`() = runBlocking {
        val node = mockNode(NameCallback().withType("NameCallback"))
        val state = ActiveNodeState().apply { set(node) }

        state.clear()

        verify(node).close()
        assertNull(state.current)
        assertFailsWith<IllegalStateException> {
            state.withItem("NameCallback", 0) { it }
        }
        Unit
    }

    @Test
    fun `clear waits for an in-flight withItem before closing the node`() = runBlocking {
        val node = mockNode(NameCallback().withType("NameCallback"))
        val state = ActiveNodeState().apply { set(node) }
        val order = CopyOnWriteArrayList<String>()
        val entered = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()

        val holder = launch {
            state.withItem("NameCallback", 0) {
                order += "item-start"
                entered.complete(Unit)
                release.await()
                order += "item-end"
            }
        }
        entered.await()
        val waiter = launch {
            state.clear()
            order += "cleared"
        }

        delay(50)
        assertEquals(listOf("item-start"), order.toList())
        assertSame(node, state.current)
        verify(node, never()).close()

        release.complete(Unit)
        holder.join()
        waiter.join()
        assertEquals(listOf("item-start", "item-end", "cleared"), order.toList())
        verify(node).close()
        assertNull(state.current)
    }

    @Test
    fun `startWith caches the node it returns`() = runBlocking {
        val state = ActiveNodeState()
        val started = mockNode(NameCallback().withType("NameCallback"))

        val result = state.startWith { started }

        assertSame(started, result)
        assertSame(started, state.current)
    }

    @Test
    fun `startWith keeps the previous node when start throws`() = runBlocking {
        val previous = mockNode(NameCallback().withType("NameCallback"))
        val state = ActiveNodeState().apply { set(previous) }

        assertFailsWith<IllegalStateException> {
            state.startWith { throw IllegalStateException("network down") }
        }

        assertSame(previous, state.current)
    }

    @Test
    fun `startWith waits for an in-flight withItem before replacing the node`() = runBlocking {
        val oldCallback = NameCallback().withType("NameCallback")
        val newCallback = NameCallback().withType("NameCallback")
        val state = ActiveNodeState().apply { set(mockNode(oldCallback)) }
        val newNode = mockNode(newCallback)
        val order = CopyOnWriteArrayList<String>()
        val entered = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()

        val holder = launch {
            state.withItem("NameCallback", 0) { item ->
                order += "item-start"
                entered.complete(Unit)
                release.await()
                // Still the old callback: the restart hasn't replaced the node under us.
                assertSame(oldCallback, item)
                order += "item-end"
            }
        }
        entered.await()
        val waiter = launch {
            state.startWith {
                order += "start"
                newNode
            }
        }

        delay(50)
        assertEquals(listOf("item-start"), order.toList())

        release.complete(Unit)
        holder.join()
        waiter.join()
        assertEquals(listOf("item-start", "item-end", "start"), order.toList())
        assertSame(newNode, state.current)
    }

    @Test
    fun `withItem excludes a concurrent withLock until the block finishes`() = runBlocking {
        val state = ActiveNodeState().apply {
            set(mockNode(NameCallback().withType("NameCallback")))
        }
        val order = CopyOnWriteArrayList<String>()
        val entered = CompletableDeferred<Unit>()
        val release = CompletableDeferred<Unit>()

        val holder = launch {
            state.withItem("NameCallback", 0) {
                order += "item-start"
                entered.complete(Unit)
                release.await()
                order += "item-end"
            }
        }
        entered.await()
        val waiter = launch { state.withLock { order += "lock" } }

        delay(50)
        assertEquals(listOf("item-start"), order.toList())

        release.complete(Unit)
        holder.join()
        waiter.join()
        assertEquals(listOf("item-start", "item-end", "lock"), order.toList())
    }

    // --- Reentrancy --------------------------------------------------------------------------

    /**
     * Runs [reenter] from inside a `withItem` block on a fresh state and asserts it is rejected
     * with the reentrancy error rather than hanging. The timeout turns a regression (a real
     * deadlock) into a failure; its own exception is also an `IllegalStateException`, so the
     * message is checked too.
     */
    private fun assertReentryRejected(reenter: suspend (ActiveNodeState) -> Unit) = runBlocking {
        val state = ActiveNodeState().apply {
            set(mockNode(NameCallback().withType("NameCallback")))
        }

        val error = assertFailsWith<IllegalStateException> {
            withTimeout(2_000) {
                state.withItem("NameCallback", 0) { reenter(state) }
            }
        }

        assertTrue(error.message.orEmpty().contains("not reentrant"), "unexpected: ${error.message}")
        // The rejected call must not have wedged the lock.
        assertEquals("ok", state.withItem("NameCallback", 0) { "ok" })
    }

    @Test
    fun `withItem inside withItem throws instead of deadlocking`() = assertReentryRejected {
        it.withItem("NameCallback", 0) { }
    }

    @Test
    fun `withLock inside withItem throws instead of deadlocking`() = assertReentryRejected {
        it.withLock { }
    }

    @Test
    fun `clear inside withItem throws instead of deadlocking`() = assertReentryRejected {
        it.clear()
    }

    @Test
    fun `startWith inside withItem throws instead of deadlocking`() = assertReentryRejected {
        it.startWith { mockNode() }
    }

    @Test
    fun `withItem inside withLock throws instead of deadlocking`() = runBlocking {
        val state = ActiveNodeState().apply {
            set(mockNode(NameCallback().withType("NameCallback")))
        }

        val error = assertFailsWith<IllegalStateException> {
            withTimeout(2_000) { state.withLock { state.withItem("NameCallback", 0) { } } }
        }

        assertTrue(error.message.orEmpty().contains("not reentrant"), "unexpected: ${error.message}")
    }

    @Test
    fun `holding one state's lock does not block using another's`() = runBlocking {
        val a = ActiveNodeState().apply { set(mockNode(NameCallback().withType("NameCallback"))) }
        val b = ActiveNodeState().apply { set(mockNode(PasswordCallback().withType("PasswordCallback"))) }

        val result = withTimeout(2_000) {
            a.withItem("NameCallback", 0) { b.withItem("PasswordCallback", 0) { "both" } }
        }

        assertEquals("both", result)
    }

    @Test
    fun `re-entering the first state is still caught while holding two`() = runBlocking {
        val a = ActiveNodeState().apply { set(mockNode(NameCallback().withType("NameCallback"))) }
        val b = ActiveNodeState().apply { set(mockNode(PasswordCallback().withType("PasswordCallback"))) }

        val error = assertFailsWith<IllegalStateException> {
            withTimeout(2_000) {
                a.withItem("NameCallback", 0) {
                    b.withItem("PasswordCallback", 0) { a.withItem("NameCallback", 0) { } }
                }
            }
        }

        assertTrue(error.message.orEmpty().contains("not reentrant"), "unexpected: ${error.message}")
    }
}
