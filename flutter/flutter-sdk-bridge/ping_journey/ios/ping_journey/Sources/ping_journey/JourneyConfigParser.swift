/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingOidc
import ping_core

/// Builds a native `Journey` from the flat, wire-serializable `JourneyConfigMessage`.
///
/// Trimmed to the fields the Pigeon schema carries (no storage/logger handle registries yet —
/// those arrive with a future module). `realm`/`cookie` are left unset when absent so the native
/// SDK's own defaults (`realm = "root"`, `cookie = "iPlanetDirectoryPro"`) apply.
enum JourneyConfigParser {
    /// Explicit cross-platform default when `JourneyConfigMessage.timeoutMillis` is unset — the
    /// native SDKs' own defaults diverge (Android 15s, iOS 30s), which otherwise makes the same
    /// unset config wait a different duration per platform with no indication in code or docs.
    static let defaultTimeoutMillis: Int64 = 30_000

    static func parse(_ message: JourneyConfigMessage) async throws -> Journey {
        let resolvedHandle: OidcConfigHandle?
        if let oidcClientId = message.oidcClientId {
            resolvedHandle = try await resolveOidcHandle(oidcClientId)
        } else {
            resolvedHandle = nil
        }

        return Journey.createJourney { journeyConfig in
            applyJourneyFields(message, to: journeyConfig)
            if let handle = resolvedHandle {
                journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
                    applyHandleFields(handle, to: oidcConfig)
                }
            } else if hasOidcFields(message) {
                journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
                    applyOidcFields(message, to: oidcConfig)
                }
            }
        }
    }

    /// Resolves [oidcClientId] from `ping_core`'s shared `CoreRuntime.oidcClientRegistry`. Not
    /// `private` so `@testable import` can exercise resolution/validation directly, without
    /// going through `parse`'s full `Journey.createJourney`.
    static func resolveOidcHandle(_ oidcClientId: String) async throws -> OidcConfigHandle {
        guard let handle = await CoreRuntime.oidcClientRegistry.resolve(oidcClientId) as? OidcConfigHandle else {
            throw JourneyHostApiError.argument("OIDC client instance not found for id=\(oidcClientId)")
        }
        let discoveryEndpoint = handle.discoveryEndpoint?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !(discoveryEndpoint == nil || discoveryEndpoint!.isEmpty) || handle.openId != nil else {
            throw JourneyHostApiError.argument(
                "OIDC client id=\(oidcClientId) does not expose discoveryEndpoint or openId. " +
                "Configure OIDC with discoveryEndpoint or openId before composing Journey."
            )
        }
        return handle
    }

    /// Applies every flat field of [handle] — resolved from `ping_core`'s shared
    /// `CoreRuntime.oidcClientRegistry` — onto [oidcConfig], in place of the inline
    /// `JourneyConfigMessage` fields. Mirrors `ping_oidc`'s own `OidcConfigParser.apply`, so the
    /// field list can't drift between the two paths. Not `private`, for the same
    /// direct-testability reason as `resolveOidcHandle`.
    static func applyHandleFields(_ handle: OidcConfigHandle, to oidcConfig: OidcClientConfig) {
        oidcConfig.clientId = handle.clientId
        if let discoveryEndpoint = handle.discoveryEndpoint { oidcConfig.discoveryEndpoint = discoveryEndpoint }
        if let openId = handle.openId {
            // openId can only be applied via openIdOverride — OidcClientConfig.openId is
            // `public private(set)` at ping-ios-sdk 2.1.0 (SDKS-5301 tracks a cleaner API). This
            // closure only fires after discover() succeeds, which requires discoveryEndpoint —
            // ping_oidc's own OidcConfigParser already guarantees any handle registered via
            // OidcClient.configure() has one, so this is safe here without re-validating.
            oidcConfig.openIdOverride = { discovered in
                discovered.authorizationEndpoint = openId.authorizationEndpoint
                discovered.tokenEndpoint = openId.tokenEndpoint
                discovered.userinfoEndpoint = openId.userinfoEndpoint
                discovered.endSessionEndpoint = openId.endSessionEndpoint ?? ""
                discovered.revocationEndpoint = openId.revocationEndpoint ?? ""
                discovered.pingEndsessionEndpoint = openId.pingEndIdpSessionEndpoint
            }
        }
        if let redirectUri = handle.redirectUri { oidcConfig.redirectUri = redirectUri }
        if !handle.scopes.isEmpty { oidcConfig.scopes = Set(handle.scopes) }
        if let acrValues = handle.acrValues { oidcConfig.acrValues = acrValues }
        // signOutRedirectUri: no equivalent field on iOS's OidcClientConfig at 2.1.0 — same
        // asymmetry already documented for the existing inline path
        // (ping_oidc/ios/.../OidcConfigParser.swift).
        if let state = handle.state { oidcConfig.state = state }
        if let nonce = handle.nonce { oidcConfig.nonce = nonce }
        if let uiLocales = handle.uiLocales { oidcConfig.uiLocales = uiLocales }
        if let refreshThreshold = handle.refreshThreshold { oidcConfig.refreshThreshold = refreshThreshold }
        if let loginHint = handle.loginHint { oidcConfig.loginHint = loginHint }
        if let display = handle.display { oidcConfig.display = display }
        if let prompt = handle.prompt { oidcConfig.prompt = prompt }
        if !handle.additionalParameters.isEmpty { oidcConfig.additionalParameters = handle.additionalParameters }
        oidcConfig.par = handle.par
    }

    private static func applyJourneyFields(_ message: JourneyConfigMessage, to journeyConfig: JourneyConfig) {
        journeyConfig.serverUrl = message.serverUrl
        if let realm = message.realm { journeyConfig.realm = realm }
        if let cookie = message.cookie { journeyConfig.cookie = cookie }
        let timeoutMillis = message.timeoutMillis ?? defaultTimeoutMillis
        journeyConfig.timeout = TimeInterval(timeoutMillis) / 1000
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
        message.oidcClientId != nil
            || message.clientId != nil
            || message.discoveryEndpoint != nil
            || message.redirectUri != nil
            || message.scopes != nil
    }
}
