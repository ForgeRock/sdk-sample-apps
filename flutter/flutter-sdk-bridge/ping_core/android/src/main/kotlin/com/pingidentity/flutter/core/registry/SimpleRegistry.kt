/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.registry

import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * In-memory, thread-safe [Registry] backed by a [ConcurrentHashMap].
 *
 * Entries are keyed by generated UUID strings.
 */
class SimpleRegistry : Registry {
    private val map = ConcurrentHashMap<String, NativeHandle>()

    override fun register(instance: NativeHandle): String {
        val id = UUID.randomUUID().toString()
        map[id] = instance
        return id
    }

    override fun resolve(id: String): NativeHandle? = map[id]

    override fun remove(id: String) {
        map.remove(id)
    }
}
