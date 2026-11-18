/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingJourneyPlugin
import PingOrchestrate

/// How a native callback is addressed on the wire: by its server-registered `"type"` and its
/// 0-based position among callbacks of that same type in the node. Shared by the value applier and
/// the active-node lookup, so the two can't drift.
enum JourneyCallbackLookup {
    /// The server-registered `"type"` string from `AbstractCallback.json`, stable across
    /// release-build symbol stripping — unlike `String(describing: type(of:))`, which reflects the
    /// Swift runtime type name and isn't a wire-format guarantee.
    static func callbackType(_ callback: any Callback) throws -> String {
        guard let abstractCallback = callback as? AbstractCallback,
              let type = abstractCallback.json[JourneyConstants.type] as? String else {
            throw JourneyHostApiError.callbackApply("Callback is missing a \"type\" field: \(callback)")
        }
        return type
    }

    /// The `index`th callback of `type` in `node`, or `nil` if there is none.
    static func find(in node: ContinueNode, type: String, index: Int) throws -> (any Callback)? {
        let matching = try node.callbacks.filter { try callbackType($0) == type }
        guard index >= 0, index < matching.count else { return nil }
        return matching[index]
    }
}
