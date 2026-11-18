/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingOrchestrate
import ping_core

/// The most recent `ContinueNode` of one Journey, plus the lock that serializes work on it.
///
/// Owned by `JourneyHandle`, so its lifetime is the handle's. A double-submitted `next()` can't
/// race two callback applications, and an add-on operation reached through
/// `JourneyHandle.withItem` can't race a `next()`, because both run on the same serializer.
///
/// Kept separate from `JourneyHandle` so it can be unit-tested without building a native `Journey`.
final class ActiveNodeState: @unchecked Sendable {
    /// `KeyedSerialExecutor` serializes per key; a state serves one Journey, so every call uses
    /// this one key.
    private static let serializerKey = "activeNode"

    private let lock = NSLock()
    private var node: ContinueNode?
    private let serializer = KeyedSerialExecutor()

    /// The current node, or `nil` if the Journey hasn't started or last returned a terminal node.
    var current: ContinueNode? {
        lock.lock()
        defer { lock.unlock() }
        return node
    }

    /// Caches `next` if it is a `ContinueNode`; any other node type leaves nothing cached.
    func set(_ next: Node) {
        lock.lock()
        defer { lock.unlock() }
        node = next as? ContinueNode
    }

    /// Drops the cached node, closing it so its `Closeable` actions can release resources.
    func clear() {
        lock.lock()
        let old = node
        node = nil
        lock.unlock()
        old?.close()
    }

    /// Runs `operation` on the serializer; `next()` runs inside this.
    func withLock<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await serializer.run(key: Self.serializerKey, operation)
    }

    /// Runs `body` with the callback at `type` / `index` of the current node, on the serializer.
    ///
    /// - Throws: `ActiveNodeError.noActiveNode` if there is no current node;
    ///   `ActiveNodeError.itemNotFound` if the node has no callback at `type` / `index`.
    func withItem<T: Sendable>(
        type: String,
        index: Int,
        _ body: @escaping @Sendable (_ item: Any) async throws -> T
    ) async throws -> T {
        try await serializer.run(key: Self.serializerKey) { [self] in
            guard let node = current else { throw ActiveNodeError.noActiveNode }
            guard let callback = try JourneyCallbackLookup.find(in: node, type: type, index: index) else {
                throw ActiveNodeError.itemNotFound(type: type, index: index)
            }
            return try await body(callback)
        }
    }
}
