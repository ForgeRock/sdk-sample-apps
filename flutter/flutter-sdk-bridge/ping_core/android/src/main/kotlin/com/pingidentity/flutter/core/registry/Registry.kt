/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.registry

/**
 * A lightweight registry for tracking native instances by generated identifiers.
 *
 * Implementations are responsible for generating stable ids, storing handles,
 * and cleaning up when entries are removed.
 */
interface Registry {
    /**
     * Register a native instance and return the generated id that can be used to
     * retrieve it later.
     */
    fun register(instance: NativeHandle): String

    /**
     * Look up a previously registered instance by id. Returns null if no match is found.
     */
    fun resolve(id: String): NativeHandle?

    /**
     * Remove a registered instance by id. Safe to call with unknown ids.
     */
    fun remove(id: String)

    /**
     * Remove all registered instances.
     */
    fun removeAll()
}
