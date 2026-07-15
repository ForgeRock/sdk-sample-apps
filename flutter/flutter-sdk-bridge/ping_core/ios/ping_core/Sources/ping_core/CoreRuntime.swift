/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// A closure that returns the callbacks for a running Journey instance.
public typealias JourneyCallbackResolver = @Sendable (String) async -> [Any]?

/// Thread-safe storage for the optional Journey callback resolver.
///
/// - Note: `@unchecked Sendable` is used because this class stores a mutable
///   closure reference that Swift cannot prove sendable. Access is serialized
///   with `NSLock`, so cross-thread mutation/read is synchronized.
private final class JourneyCallbackResolverStore: @unchecked Sendable {
    private let lock = NSLock()
    private var resolver: JourneyCallbackResolver?

    func set(_ resolver: JourneyCallbackResolver?) {
        lock.lock()
        self.resolver = resolver
        lock.unlock()
    }

    func get() -> JourneyCallbackResolver? {
        lock.lock()
        let current = resolver
        lock.unlock()
        return current
    }
}

/// Central place to hold process-wide registries used by the core module.
///
/// Keeps native handles alive across calls from the Flutter bridge. Every future native module
/// (oidc, davinci, storage, ...) shares this same type, so it must live in `ping_core` rather
/// than in any single feature plugin.
public enum CoreRuntime {
    /// Registry for Journey client instances.
    public static let journeyRegistry: Registry = SimpleRegistry()

    /// Internal resolver store used to avoid shared mutable global state.
    private static let journeyCallbackResolverStore = JourneyCallbackResolverStore()

    /// Registers or clears the resolver that exposes Journey callbacks to other packages.
    ///
    /// - Parameter resolver: Resolver closure to register, or `nil` to clear.
    public static func setJourneyCallbackResolver(_ resolver: JourneyCallbackResolver?) {
        journeyCallbackResolverStore.set(resolver)
    }

    /// Resolves Journey callbacks for the given journey instance via the registered resolver.
    public static func resolveJourneyCallbacks(
        _ journeyId: String
    ) async -> [Any]? {
        guard let resolver = journeyCallbackResolverStore.get() else {
            return nil
        }
        return await resolver(journeyId)
    }
}
