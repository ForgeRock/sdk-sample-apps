/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import android.util.Log
import com.pingidentity.flutter.journey.callback.JourneyCallbackLookup
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.Node
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext

/**
 * The most recent [ContinueNode] of one Journey, plus the lock that serializes work on it.
 *
 * Owned by [JourneyHandle], so its lifetime is the handle's. A double-submitted `next()` can't race
 * two callback applications, and an add-on operation reached through
 * [JourneyHandle.withItem] can't race a `next()`, because both run under the same [Mutex].
 *
 * The lock is not reentrant, and entering it again from inside a block already running under it
 * would wait on itself forever. Every entry point checks for that and throws
 * [IllegalStateException] instead. The check follows the coroutine context, so it catches a nested
 * call made from the same coroutine (or one it launched), not a call made from an unrelated
 * coroutine, which simply waits its turn.
 *
 * Kept separate from [JourneyHandle] so it can be unit-tested without building a native `Journey`.
 */
internal class ActiveNodeState {
    private val mutex = Mutex()

    @Volatile
    private var node: ContinueNode? = null

    /** The current node, or `null` if the Journey hasn't started or last returned a terminal node. */
    val current: ContinueNode?
        get() = node

    /**
     * Caches [next] if it is a [ContinueNode]; any other node type leaves nothing cached.
     *
     * Does not take the lock and does not close the node it replaces (the native `next()` already
     * does). Call it only while holding the lock: inside [withLock], or through [startWith].
     */
    fun set(next: Node) {
        node = next as? ContinueNode
    }

    /**
     * Drops the cached node, closing it so its `Closeable` actions can release resources.
     *
     * Takes the lock, so it waits for an in-flight [withItem] or `next()` instead of closing the
     * node out from under it.
     */
    suspend fun clear() {
        locked {
            val old = node
            node = null
            if (old != null) {
                runCatching { old.close() }
                    .onFailure { Log.w(TAG, "Failed to close ContinueNode", it) }
            }
        }
    }

    /**
     * Runs [start] holding the lock and caches the node it returns, so a Journey restart can't swap
     * the node while an add-on operation or `next()` is using the previous one.
     *
     * If [start] throws, nothing is cached and the previous node is left in place.
     */
    suspend fun startWith(start: suspend () -> Node): Node =
        locked { start().also { set(it) } }

    /**
     * Runs [block] holding the lock; `next()` runs inside this.
     *
     * @throws IllegalStateException if called from inside a block already holding this lock
     */
    suspend fun <T> withLock(block: suspend () -> T): T = locked(block)

    /**
     * Runs [block] with the callback at [type] / [index] of the current node, holding the lock.
     *
     * @throws IllegalStateException if there is no current node, or if called from inside a block
     *   already holding this lock
     * @throws IllegalArgumentException if the node has no callback at [type] / [index]
     */
    suspend fun <T> withItem(type: String, index: Int, block: suspend (item: Any) -> T): T =
        locked {
            val current = node ?: throw IllegalStateException("No active ContinueNode")
            val callback =
                JourneyCallbackLookup.find(current, type, index)
                    ?: throw IllegalArgumentException(
                        "No active callback found for type $type at index $index"
                    )
            block(callback)
        }

    /**
     * Takes the lock and runs [block] with this state recorded in the coroutine context, so a
     * nested entry from inside [block] is rejected up front instead of deadlocking on [mutex].
     */
    private suspend fun <T> locked(block: suspend () -> T): T {
        val held = currentCoroutineContext()[HeldLocks]?.states.orEmpty()
        check(this !in held) {
            "ActiveNodeState's lock is not reentrant: it was entered again from inside a block " +
                "already holding it"
        }
        return mutex.withLock { withContext(HeldLocks(held + this)) { block() } }
    }

    /**
     * Context element naming the states whose lock the current coroutine holds. A set rather than
     * a single state, so holding one Journey's lock while using another's still works, and
     * re-entering the first one is still caught.
     */
    private class HeldLocks(val states: Set<ActiveNodeState>) :
        AbstractCoroutineContextElement(HeldLocks) {
        companion object Key : CoroutineContext.Key<HeldLocks>
    }

    private companion object {
        const val TAG = "ActiveNodeState"
    }
}
