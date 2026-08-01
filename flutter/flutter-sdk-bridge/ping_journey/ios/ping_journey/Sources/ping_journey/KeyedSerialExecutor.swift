/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// Serializes async work per key: two calls to `run(key:_:)` with the same `key` never overlap,
/// while calls with different keys run concurrently. Used to prevent a double-submitted `next()`
/// for the same `journeyId` from racing on the same cached `ContinueNode`'s callback fields.
actor KeyedSerialExecutor {
    private var tails: [String: Task<Void, Never>] = [:]
    private var generations: [String: UInt64] = [:]

    func run<T: Sendable>(key: String, _ operation: @Sendable @escaping () async throws -> T) async throws -> T {
        let previousTail = tails[key]
        let generation = (generations[key] ?? 0) &+ 1
        generations[key] = generation

        let box = Box<T>()
        let tail = Task {
            _ = await previousTail?.value
            await box.set(result: await Self.runCatching(operation))
        }
        tails[key] = tail

        await tail.value
        if generations[key] == generation {
            tails.removeValue(forKey: key)
            generations.removeValue(forKey: key)
        }
        return try box.get()
    }

    /// Drops any pending chain for `key`, e.g. once its journey is disposed.
    func remove(key: String) {
        tails.removeValue(forKey: key)
        generations.removeValue(forKey: key)
    }

    private static func runCatching<T>(_ operation: () async throws -> T) async -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    }
}

/// Single-slot holder for a `Result` set exactly once from within the executor's serialized chain.
private final class Box<T>: @unchecked Sendable {
    private var result: Result<T, Error>?

    func set(result: Result<T, Error>) {
        self.result = result
    }

    func get() throws -> T {
        // Safe force-unwrap: `run(key:_:)` always calls `set` before reading via `get`.
        try result!.get()
    }
}
