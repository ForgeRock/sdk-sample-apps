/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingOidc

/// Maps a flat `OidcConfigMessage` onto the native SDK's `OidcClientConfig`.
///
/// The native SDK only reports a missing `discoveryEndpoint`/`openId` on first use, so this parser
/// checks up front and `configureOidc` fails fast with a typed error.
///
/// An openId-only config is assigned directly and skips discovery. With a `discoveryEndpoint` too,
/// `openId` patches the discovered document instead. Both rules match Android.
enum OidcConfigParser {
    static func parse(_ message: OidcConfigMessage) throws -> OidcClientConfig {
        guard message.discoveryEndpoint != nil || message.openId != nil else {
            throw OidcHostApiError.argumentError(
                "OidcConfigMessage must set either discoveryEndpoint or openId"
            )
        }
        let config = OidcClientConfig()
        apply(config, from: message)
        return config
    }

    /// Maps every flat field of [message] onto [config]. Shared by `parse` (builds a standalone
    /// config) and `OidcWebClientFactory` (applies the same fields inside a
    /// `module(OidcModule.config) { }` block, which hands back the identical `OidcClientConfig`
    /// type) so the field list can't drift between the two call sites.
    static func apply(_ config: OidcClientConfig, from message: OidcConfigMessage) {
        config.clientId = message.clientId
        config.redirectUri = message.redirectUri
        if let discoveryEndpoint = message.discoveryEndpoint {
            config.discoveryEndpoint = discoveryEndpoint
        }
        if let openId = message.openId {
            if message.discoveryEndpoint == nil {
                config.openId = OpenIdConfiguration(
                    authorizationEndpoint: openId.authorizationEndpoint,
                    tokenEndpoint: openId.tokenEndpoint,
                    userinfoEndpoint: openId.userinfoEndpoint,
                    endSessionEndpoint: openId.endSessionEndpoint ?? "",
                    revocationEndpoint: openId.revocationEndpoint ?? "",
                    pingEndsessionEndpoint: openId.pingEndIdpSessionEndpoint
                )
            } else {
                // Patch the discovered document, so endpoints openId doesn't carry (e.g. PAR)
                // still come from discovery. Android does the same.
                config.openIdOverride = { discovered in
                    discovered.authorizationEndpoint = openId.authorizationEndpoint
                    discovered.tokenEndpoint = openId.tokenEndpoint
                    discovered.userinfoEndpoint = openId.userinfoEndpoint
                    if let value = openId.endSessionEndpoint { discovered.endSessionEndpoint = value }
                    if let value = openId.revocationEndpoint { discovered.revocationEndpoint = value }
                    if let value = openId.pingEndIdpSessionEndpoint { discovered.pingEndsessionEndpoint = value }
                }
            }
        }
        if let scopes = message.scopes {
            config.scopes = Set(scopes.compactMap { $0 })
        }
        if let acrValues = message.acrValues { config.acrValues = acrValues }
        // signOutRedirectUri intentionally dropped — no such property on iOS's OidcClientConfig.
        if let state = message.state { config.state = state }
        if let nonce = message.nonce { config.nonce = nonce }
        if let uiLocales = message.uiLocales { config.uiLocales = uiLocales }
        if let seconds = message.refreshThresholdSeconds { config.refreshThreshold = seconds }
        if let loginHint = message.loginHint { config.loginHint = loginHint }
        if let display = message.display { config.display = display }
        if let prompt = message.prompt { config.prompt = prompt }
        if let params = message.additionalParameters {
            config.additionalParameters = params.reduce(into: [String: String]()) { result, entry in
                if let key = entry.key, let value = entry.value { result[key] = value }
            }
        }
        config.par = message.par
    }
}
