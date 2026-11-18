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
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * The most recent [ContinueNode] of one Journey, plus the lock that serializes work on it.
 *
 * Owned by [JourneyHandle], so its lifetime is the handle's. A double-submitted `next()` can't race
 * two callback applications, and an add-on operation reached through
 * [JourneyHandle.withItem] can't race a `next()`, because both run under the same [Mutex].
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

    /** Caches [next] if it is a [ContinueNode]; any other node type leaves nothing cached. */
    fun set(next: Node) {
        node = next as? ContinueNode
    }

    /** Drops the cached node, closing it so its `Closeable` actions can release resources. */
    fun clear() {
        val old = node
        node = null
        if (old != null) {
            runCatching { old.close() }
                .onFailure { Log.w(TAG, "Failed to close ContinueNode", it) }
        }
    }

    /** Runs [block] holding the lock; `next()` runs inside this. */
    suspend fun <T> withLock(block: suspend () -> T): T = mutex.withLock { block() }

    /**
     * Runs [block] with the callback at [type] / [index] of the current node, holding the lock.
     *
     * @throws IllegalStateException if there is no current node
     * @throws IllegalArgumentException if the node has no callback at [type] / [index]
     */
    suspend fun <T> withItem(type: String, index: Int, block: suspend (item: Any) -> T): T =
        mutex.withLock {
            val current = node ?: throw IllegalStateException("No active ContinueNode")
            val callback =
                JourneyCallbackLookup.find(current, type, index)
                    ?: throw IllegalArgumentException(
                        "No active callback found for type $type at index $index"
                    )
            block(callback)
        }

    private companion object {
        const val TAG = "ActiveNodeState"
    }
}
