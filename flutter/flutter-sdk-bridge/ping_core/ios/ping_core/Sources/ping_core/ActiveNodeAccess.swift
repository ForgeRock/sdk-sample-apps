/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// A `NativeHandle` that lets an add-on plugin (device profile, binding, FIDO, ...) reach an item of
/// the handle's current node — a Journey callback or a DaVinci collector — without depending on the
/// module that owns the handle or on its SDK types.
///
/// Declared here, in `ping_core`, for the same reason as `OidcConfigHandle`: the contract uses only
/// primitives and `Any`. The owning module's handle (`ping_journey`'s `JourneyHandle`, ...)
/// conforms to it; an add-on resolves the handle by id from the matching `CoreRuntime` registry,
/// casts it to this protocol, and casts the item to the native type it owns.
public protocol ActiveNodeAccess: NativeHandle {
    /// Runs `body` with the item of the current node identified by `type` and `index`, while
    /// holding the same lock that serializes `next()` for this handle. An operation in progress
    /// therefore can't race a submit on the same item.
    ///
    /// The item is only valid inside `body`: every `next()` replaces the node, so never keep a
    /// reference to it. The lock is not reentrant: `body` must not call back into `next()` for the
    /// same handle, or it deadlocks.
    ///
    /// - Parameters:
    ///   - type: the server-registered type string, as sent in the wire message's `type`.
    ///   - index: 0-based position among items of the same `type` in the current node.
    /// - Throws: `ActiveNodeError.noActiveNode` if the handle has no active node;
    ///   `ActiveNodeError.itemNotFound` if the node has no item at `type` / `index`.
    func withItem<T: Sendable>(
        type: String,
        index: Int,
        _ body: @escaping @Sendable (_ item: Any) async throws -> T
    ) async throws -> T
}

/// Failures of `ActiveNodeAccess` and its lookup. Defined here so an add-on can classify them
/// without depending on the module that owns the handle.
public enum ActiveNodeError: Error, CustomStringConvertible {
    /// No handle with an `ActiveNodeAccess` conformance is registered under the id.
    case notFound(id: String)
    /// The handle has no current node.
    case noActiveNode
    /// The current node has no item at the requested type and index.
    case itemNotFound(type: String, index: Int)

    public var description: String {
        switch self {
        case .notFound(let id):
            return "Active node instance not found for id=\(id)"
        case .noActiveNode:
            return "No active ContinueNode"
        case .itemNotFound(let type, let index):
            return "No active item found for type \(type) at index \(index)"
        }
    }
}

extension Registry {
    /// Resolves `id` to an `ActiveNodeAccess`, or throws `ActiveNodeError.notFound` when it is
    /// unknown or its handle doesn't support item access — the same failure an add-on would see if
    /// the owning module weren't installed.
    public func requireActiveNode(_ id: String) async throws -> ActiveNodeAccess {
        guard let access = await resolve(id) as? ActiveNodeAccess else {
            throw ActiveNodeError.notFound(id: id)
        }
        return access
    }
}
