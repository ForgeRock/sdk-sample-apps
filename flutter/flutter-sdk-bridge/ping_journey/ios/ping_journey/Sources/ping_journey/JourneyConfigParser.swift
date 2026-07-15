/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingOidc

/// Builds a native `Journey` from the flat, wire-serializable `JourneyConfigMessage`.
///
/// Trimmed to the fields the Pigeon schema carries (no storage/logger handle registries yet —
/// those arrive with a future module). `realm`/`cookie` are left unset when absent so the native
/// SDK's own defaults (`realm = "root"`, `cookie = "iPlanetDirectoryPro"`) apply.
enum JourneyConfigParser {
    static func parse(_ message: JourneyConfigMessage) -> Journey {
        Journey.createJourney { journeyConfig in
            applyJourneyFields(message, to: journeyConfig)
            if hasOidcFields(message) {
                journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
                    applyOidcFields(message, to: oidcConfig)
                }
            }
        }
    }

    private static func applyJourneyFields(_ message: JourneyConfigMessage, to journeyConfig: JourneyConfig) {
        journeyConfig.serverUrl = message.serverUrl
        if let realm = message.realm { journeyConfig.realm = realm }
        if let cookie = message.cookie { journeyConfig.cookie = cookie }
        if let timeoutMillis = message.timeoutMillis {
            journeyConfig.timeout = TimeInterval(timeoutMillis) / 1000
        }
    }

    private static func applyOidcFields(_ message: JourneyConfigMessage, to oidcConfig: OidcClientConfig) {
        if let clientId = message.clientId { oidcConfig.clientId = clientId }
        if let discoveryEndpoint = message.discoveryEndpoint {
            oidcConfig.discoveryEndpoint = discoveryEndpoint
        }
        if let redirectUri = message.redirectUri { oidcConfig.redirectUri = redirectUri }
        if let scopes = message.scopes {
            oidcConfig.scopes = Set(scopes.compactMap { $0 })
        }
        if let acrValues = message.acrValues { oidcConfig.acrValues = acrValues }
        if let state = message.state { oidcConfig.state = state }
        if let nonce = message.nonce { oidcConfig.nonce = nonce }
        if let uiLocales = message.uiLocales { oidcConfig.uiLocales = uiLocales }
        if let refreshThreshold = message.refreshThreshold {
            oidcConfig.refreshThreshold = refreshThreshold
        }
        if let loginHint = message.loginHint { oidcConfig.loginHint = loginHint }
        if let display = message.display { oidcConfig.display = display }
        if let prompt = message.prompt { oidcConfig.prompt = prompt }
        if let additionalParameters = message.additionalParameters {
            oidcConfig.additionalParameters = additionalParameters.reduce(into: [String: String]()) { result, entry in
                if let key = entry.key, let value = entry.value {
                    result[key] = value
                }
            }
        }
    }

    static func hasOidcFields(_ message: JourneyConfigMessage) -> Bool {
        message.clientId != nil
            || message.discoveryEndpoint != nil
            || message.redirectUri != nil
            || message.scopes != nil
    }
}
