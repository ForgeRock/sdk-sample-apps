/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey.callback

import com.pingidentity.journey.plugin.AbstractCallback
import com.pingidentity.journey.plugin.Callback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.orchestrate.ContinueNode
import kotlinx.serialization.json.jsonPrimitive

/**
 * How a native callback is addressed on the wire: by its server-registered `"type"` and its
 * 0-based position among callbacks of that same type in the node. Shared by the node mapper (which
 * assigns the index), the value applier and the active-node lookup (which resolve it), so the three
 * can't drift.
 */
internal object JourneyCallbackLookup {
    /**
     * The server-registered `"type"` string from [AbstractCallback.json], stable across R8/proguard
     * minification — unlike [Any.javaClass]'s `simpleName`, which is obfuscated in a minified build.
     */
    fun callbackType(callback: Callback): String =
        (callback as AbstractCallback).json["type"]?.jsonPrimitive?.content
            ?: throw IllegalStateException("Callback is missing a \"type\" field: $callback")

    /** The [index]th callback of [type] in [node], or `null` if there is none. */
    fun find(node: ContinueNode, type: String, index: Int): Callback? =
        node.callbacks.filter { callbackType(it) == type }.getOrNull(index)
}
