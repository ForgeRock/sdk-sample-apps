/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// In-memory actor-isolated `Registry` backed by a dictionary.
///
/// Entries are keyed by generated UUID strings and actor isolation
/// keeps mutations safe across concurrent calls.
public actor SimpleRegistry: Registry {
    private var map: [String: NativeHandle] = [:]

    public init() {}

    /// Store the handle and return a fresh UUID key.
    public func register(_ instance: NativeHandle) async -> String {
        let id = UUID().uuidString
        map[id] = instance
        return id
    }

    /// Retrieve a handle by id, or `nil` when missing.
    public func resolve(_ id: String) async -> NativeHandle? {
        map[id]
    }

    /// Remove a handle by id; no-op when it does not exist.
    public func remove(_ id: String) async {
        map.removeValue(forKey: id)
    }

    /// Clear all stored handles.
    public func removeAll() async {
        map.removeAll()
    }
}
