/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// Lightweight registry for tracking native instances by generated identifiers.
///
/// Implementations generate stable ids, store handles,
/// and clean up when entries are removed.
public protocol Registry: Sendable {
    /// Register a native instance and return the generated id that can be used to retrieve it later.
    func register(_ instance: NativeHandle) async -> String

    /// Look up a previously registered instance by id. Returns `nil` if no match is found.
    func resolve(_ id: String) async -> NativeHandle?

    /// Remove a registered instance by id. Safe to call with unknown ids.
    func remove(_ id: String) async

    /// Remove all registered instances.
    func removeAll() async
}
