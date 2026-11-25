/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.node

import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.flutter.core.registry.Registry

/**
 * A [NativeHandle] that lets an add-on plugin (device profile, binding, FIDO, ...) reach an item of
 * the handle's current node — a Journey callback or a DaVinci collector — without depending on the
 * module that owns the handle or on its SDK types.
 *
 * Declared here, in `ping_core`, for the same reason as `OidcConfigHandle`: the contract uses only
 * primitives and [Any]. The owning module's handle (`ping_journey`'s `JourneyHandle`, ...)
 * implements it; an add-on resolves the handle by id from the matching `CoreRuntime` registry,
 * casts it to this interface, and casts the item to the native type it owns.
 */
interface ActiveNodeAccess : NativeHandle {
    /**
     * Runs [block] with the item of the current node identified by [type] and [index], while
     * holding the same lock that serializes `next()` for this handle. An operation in progress
     * therefore can't race a submit on the same item.
     *
     * The item is only valid inside [block]: every `next()` replaces the node, so never keep a
     * reference to it. The lock is not reentrant: calling [withItem] on the same handle from inside
     * [block] throws [IllegalStateException] instead of deadlocking. [block] must also not wait on
     * `next()` for the same handle: that runs separately, waits for the lock [block] holds, and
     * can't be detected as reentry.
     *
     * @param type the server-registered type string, as sent in the wire message's `type`
     * @param index the item's 0-based index, as the owning module put it on the wire. What it
     *   counts is that module's convention: a Journey counts among callbacks of the same [type],
     *   while DaVinci's collector index counts across the whole node regardless of type.
     * @throws IllegalStateException if the handle has no active node, or if called from inside a
     *   block already holding the handle's lock
     * @throws IllegalArgumentException if the node has no item at [type] / [index]
     */
    suspend fun <T> withItem(type: String, index: Int, block: suspend (item: Any) -> T): T
}

/**
 * Resolves [id] to an [ActiveNodeAccess], or throws [IllegalStateException] naming the id when it
 * is unknown or its handle doesn't support item access — the same failure an add-on would see if
 * the owning module weren't installed.
 */
fun Registry.requireActiveNode(id: String): ActiveNodeAccess =
    resolve(id) as? ActiveNodeAccess
        ?: throw IllegalStateException("Active node instance not found for id=$id")
