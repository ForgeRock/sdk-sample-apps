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
/// The lock is not reentrant, and entering it again from inside an operation already running under
/// it would wait on itself forever. Every entry point checks for that and throws
/// `ActiveNodeError.reentrantLock` instead. The check follows the task's task-locals, so it catches
/// a nested call made from the same task (or a child task it started), not a call made from an
/// unrelated task, which simply waits its turn.
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
    ///
    /// Does not run on the serializer and does not close the node it replaces (the native `next()`
    /// already does). Call it only from work already running on the serializer: inside `withLock`,
    /// or through `startWith`.
    func set(_ next: Node) {
        lock.lock()
        defer { lock.unlock() }
        node = next as? ContinueNode
    }

    /// Drops the cached node, closing it so its `Closeable` actions can release resources.
    ///
    /// Runs on the serializer, so it waits for an in-flight `withItem` or `next()` instead of
    /// closing the node out from under it.
    ///
    /// - Throws: `ActiveNodeError.reentrantLock` if called from inside an operation already holding
    ///   this lock.
    func clear() async throws {
        try await serialized { [self] in
            lock.lock()
            let old = node
            node = nil
            lock.unlock()
            old?.close()
        }
    }

    /// Runs `start` on the serializer and caches the node it returns, so a Journey restart can't
    /// swap the node while an add-on operation or `next()` is using the previous one.
    ///
    /// - Throws: `ActiveNodeError.reentrantLock` if called from inside an operation already holding
    ///   this lock.
    func startWith(_ start: @escaping @Sendable () async -> Node) async throws -> Node {
        try await serialized { [self] in
            let started = await start()
            set(started)
            return started
        }
    }

    /// Runs `operation` on the serializer; `next()` runs inside this.
    ///
    /// - Throws: `ActiveNodeError.reentrantLock` if called from inside an operation already holding
    ///   this lock.
    func withLock<T: Sendable>(_ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await serialized(operation)
    }

    /// Runs `body` with the callback at `type` / `index` of the current node, on the serializer.
    ///
    /// - Throws: `ActiveNodeError.noActiveNode` if there is no current node;
    ///   `ActiveNodeError.itemNotFound` if the node has no callback at `type` / `index`;
    ///   `ActiveNodeError.reentrantLock` if called from inside an operation already holding this
    ///   lock.
    func withItem<T: Sendable>(
        type: String,
        index: Int,
        _ body: @escaping @Sendable (_ item: Any) async throws -> T
    ) async throws -> T {
        try await serialized { [self] in
            guard let node = current else { throw ActiveNodeError.noActiveNode }
            guard let callback = try JourneyCallbackLookup.find(in: node, type: type, index: index) else {
                throw ActiveNodeError.itemNotFound(type: type, index: index)
            }
            return try await body(callback)
        }
    }

    /// Runs `operation` on the serializer with this state recorded in a task-local, so a nested
    /// entry from inside `operation` is rejected up front instead of deadlocking on the serializer.
    ///
    /// The task-local is a set rather than a single state, so holding one Journey's lock while
    /// using another's still works, and re-entering the first one is still caught.
    private func serialized<T: Sendable>(
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let id = ObjectIdentifier(self)
        let held = HeldLocks.states
        guard !held.contains(id) else { throw ActiveNodeError.reentrantLock }
        return try await serializer.run(key: Self.serializerKey) {
            try await HeldLocks.$states.withValue(held.union([id])) {
                try await operation()
            }
        }
    }
}

/// The states whose serializer the current task is running under. Task-locals are inherited by the
/// child tasks `KeyedSerialExecutor` creates, so the value set around `operation` is what a nested
/// call from inside it reads.
private enum HeldLocks {
    @TaskLocal static var states: Set<ObjectIdentifier> = []
}
