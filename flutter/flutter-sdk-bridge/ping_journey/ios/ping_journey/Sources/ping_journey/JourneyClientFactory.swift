/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import ping_core

/// Wraps a live native `Journey` so it can be stored in `CoreRuntime.journeyRegistry`.
///
/// `hasOidc` records whether the `JourneyConfigMessage` this journey was built from actually
/// configured an Oidc module — `Journey.journeyUser()` unconditionally registers an Oidc module
/// internally and never returns nil, so callers must check this flag *before* touching
/// `journeyUser()`/`token()` on a session-only Journey.
final class JourneyHandle: NativeHandle, @unchecked Sendable {
    let journey: Journey
    let hasOidc: Bool

    init(journey: Journey, hasOidc: Bool) {
        self.journey = journey
        self.hasOidc = hasOidc
    }
}

/// Builds a native `Journey` from a `JourneyConfigMessage` and registers it in the shared
/// core registry, returning the generated `journeyId`.
enum JourneyClientFactory {
    static func create(_ config: JourneyConfigMessage) async throws -> String {
        let journey = JourneyConfigParser.parse(config)
        let handle = JourneyHandle(journey: journey, hasOidc: JourneyConfigParser.hasOidcFields(config))
        return await CoreRuntime.journeyRegistry.register(handle)
    }
}
