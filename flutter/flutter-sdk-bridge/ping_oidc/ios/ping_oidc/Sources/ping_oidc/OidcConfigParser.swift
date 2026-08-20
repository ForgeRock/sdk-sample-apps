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
/// Neither native SDK validates at construction time whether a client can actually discover or
/// resolve an OpenID configuration (iOS's `discoveryEndpoint`/`clientId`/`redirectUri` default to
/// `""`; `discover()` just logs and returns `nil` for an empty/invalid URL rather than throwing).
/// This parser performs that validation itself so `configureOidc` fails fast with a typed error.
///
/// ⚠️ **`openId` cannot be assigned directly on iOS at 2.1.0.** It is
/// `public private(set) var` — Swift scopes `private(set)` to the declaring *file*, and a
/// compiled build against the real `ping-ios-sdk` checkout confirms the setter is genuinely
/// inaccessible from `ping_oidc` ("setter is inaccessible"). The only public mechanism that can
/// influence `openId` from outside `OidcClientConfig.swift` is `openIdOverride`, a closure
/// `oidcInitialize()` invokes **only after `discover()` returns a non-nil value** — i.e. only
/// after a real discovery network call already succeeded. 
/// 
/// TODO: Filed [SDKS-5301](https://pingidentity.atlassian.net/browse/SDKS-5301) against `ping-ios-sdk`,
/// requesting a public "skip discovery" entry point (the SDK already has an internal
/// `setOpenId(_:)` marked test-only — promoting it is one candidate fix). Remove this guard once
/// that's available.
enum OidcConfigParser {
    static func parse(_ message: OidcConfigMessage) throws -> OidcClientConfig {
        guard message.discoveryEndpoint != nil || message.openId != nil else {
            throw OidcHostApiError.argumentError(
                "OidcConfigMessage must set either discoveryEndpoint or openId"
            )
        }
        guard message.discoveryEndpoint != nil || message.openId == nil else {
            throw OidcHostApiError.argumentError(
                "An openId-only config (no discoveryEndpoint) is not supported on iOS at " +
                "ping-ios-sdk 2.1.0: OidcClientConfig.openId is only settable via " +
                "openIdOverride, which fires only after a successful discover() call. Set " +
                "discoveryEndpoint (optionally alongside openId to override its values)."
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
            config.openIdOverride = { discovered in
                discovered.authorizationEndpoint = openId.authorizationEndpoint
                discovered.tokenEndpoint = openId.tokenEndpoint
                discovered.userinfoEndpoint = openId.userinfoEndpoint
                discovered.endSessionEndpoint = openId.endSessionEndpoint ?? ""
                discovered.revocationEndpoint = openId.revocationEndpoint ?? ""
                discovered.pingEndsessionEndpoint = openId.pingEndIdpSessionEndpoint
            }
        }
        if let scopes = message.scopes {
            config.scopes = Set(scopes.compactMap { $0 })
        }
        if let acrValues = message.acrValues { config.acrValues = acrValues }
        // signOutRedirectUri intentionally dropped — OidcClientConfig has no such property on
        // iOS at 2.1.0 (confirmed via source read; only mentioned as a silently-ignored JSON key
        // in `apply(json:)`'s doc comment). Same known asymmetry already documented for
        // ping_journey's JourneyConfigParser.
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
