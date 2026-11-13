/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingDavinci
import PingLogger
import PingOidc
import ping_core

/// Builds a native DaVinci workflow from the flat, wire-serializable `DaVinciConfigMessage`.
///
/// The OIDC module is configured from exactly one source: the hoisted message fields, or a handle
/// resolved from `ping_core`'s `CoreRuntime.oidcClientRegistry` via `oidcClientId`. `validate`
/// enforces that before anything is built. Mirrors the Android parser.
enum DaVinciConfigParser {
    /// Applied when `DaVinciConfigMessage.timeoutMillis` is unset. Both native SDKs default to 15s
    /// for DaVinci; passing it explicitly keeps the platforms aligned if either default moves.
    static let defaultTimeoutMillis: Int64 = 15_000

    static func parse(_ message: DaVinciConfigMessage) async throws -> DaVinci {
        try validate(message)
        let handle: OidcConfigHandle?
        if let oidcClientId = message.oidcClientId {
            handle = try await resolveOidcHandle(oidcClientId)
        } else {
            handle = nil
        }

        return DaVinci.createDaVinci { config in
            let timeoutMillis = message.timeoutMillis ?? defaultTimeoutMillis
            config.timeout = TimeInterval(timeoutMillis) / 1000
            // The native iOS logger is process-global (`WorkflowConfig.logger`'s setter also
            // assigns `LogManager.logger`), so the most recent `configure` call's level wins.
            config.logger = logger(for: message.logLevel)
            // Qualified: PingOidc declares an `OidcModule` too.
            config.module(PingDavinci.OidcModule.config) { oidcConfig in
                if let handle {
                    applyHandleFields(handle, to: oidcConfig)
                } else {
                    applyMessageFields(message, to: oidcConfig)
                }
            }
        }
    }

    /// Throws `DaVinciHostApiError.argument` unless `message` configures OIDC through exactly one
    /// path: `oidcClientId`, or the hoisted fields with a `clientId`, a `redirectUri`, and a
    /// `discoveryEndpoint` or `openId`. Not `private`, so `@testable import` can reach it.
    static func validate(_ message: DaVinciConfigMessage) throws {
        if message.oidcClientId != nil {
            if hasInlineOidcFields(message) {
                throw DaVinciHostApiError.argument(
                    "DaVinciConfigMessage.oidcClientId cannot be combined with any inline OIDC field — " +
                    "configure OIDC through exactly one path."
                )
            }
            return
        }
        guard !isBlank(message.clientId) else {
            throw DaVinciHostApiError.argument(
                "DaVinciConfigMessage requires clientId, or oidcClientId to reuse a configured OIDC client."
            )
        }
        guard !isBlank(message.redirectUri) else {
            throw DaVinciHostApiError.argument("DaVinciConfigMessage requires redirectUri.")
        }
        guard !isBlank(message.discoveryEndpoint) || message.openId != nil else {
            throw DaVinciHostApiError.argument("DaVinciConfigMessage requires discoveryEndpoint or openId.")
        }
    }

    /// Whether `message` sets any hoisted OIDC field — every one, so none is silently dropped.
    static func hasInlineOidcFields(_ message: DaVinciConfigMessage) -> Bool {
        message.clientId != nil
            || message.discoveryEndpoint != nil
            || message.openId != nil
            || message.redirectUri != nil
            || message.scopes != nil
            || message.acrValues != nil
            || message.signOutRedirectUri != nil
            || message.state != nil
            || message.nonce != nil
            || message.uiLocales != nil
            || message.refreshThreshold != nil
            || message.loginHint != nil
            || message.display != nil
            || message.prompt != nil
            || message.additionalParameters != nil
            || message.par != nil
    }

    /// Resolves `oidcClientId` from `ping_core`'s shared `CoreRuntime.oidcClientRegistry`, and
    /// validates it exposes a usable configuration. Same rule as `ping_journey`'s.
    static func resolveOidcHandle(_ oidcClientId: String) async throws -> OidcConfigHandle {
        guard let handle = await CoreRuntime.oidcClientRegistry.resolve(oidcClientId) as? OidcConfigHandle else {
            throw DaVinciHostApiError.argument("OIDC client instance not found for id=\(oidcClientId)")
        }
        guard !isBlank(handle.discoveryEndpoint) || handle.openId != nil else {
            throw DaVinciHostApiError.argument(
                "OIDC client id=\(oidcClientId) does not expose discoveryEndpoint or openId. " +
                "Configure OIDC with discoveryEndpoint or openId before composing DaVinci."
            )
        }
        return handle
    }

    /// Maps `DaVinciConfigMessage.logLevel` onto a native `Logger`. Defaults to `LogManager.none`
    /// (the native default): `standard` routes every SDK request/response through the system log,
    /// which can surface token material, so it is opt-in.
    static func logger(for level: DaVinciLogLevel?) -> Logger {
        switch level {
        case .standard: return LogManager.standard
        default: return LogManager.none
        }
    }

    /// Applies the hoisted OIDC fields of `message` onto `oidcConfig`. Mirrors `ping_oidc`'s
    /// `OidcConfigParser.apply`. Not shared through `ping_core`, which has no native SDK
    /// dependency.
    static func applyMessageFields(_ message: DaVinciConfigMessage, to oidcConfig: OidcClientConfig) {
        if let clientId = message.clientId { oidcConfig.clientId = clientId }
        if let redirectUri = message.redirectUri { oidcConfig.redirectUri = redirectUri }
        if let discoveryEndpoint = message.discoveryEndpoint { oidcConfig.discoveryEndpoint = discoveryEndpoint }
        if let openId = message.openId {
            applyOpenId(
                to: oidcConfig,
                discovered: message.discoveryEndpoint != nil,
                authorizationEndpoint: openId.authorizationEndpoint,
                tokenEndpoint: openId.tokenEndpoint,
                userinfoEndpoint: openId.userinfoEndpoint,
                endSessionEndpoint: openId.endSessionEndpoint,
                pingEndIdpSessionEndpoint: openId.pingEndIdpSessionEndpoint,
                revocationEndpoint: openId.revocationEndpoint
            )
        }
        if let scopes = message.scopes { oidcConfig.scopes = Set(scopes.compactMap { $0 }) }
        if let acrValues = message.acrValues { oidcConfig.acrValues = acrValues }
        // signOutRedirectUri: no equivalent field on iOS's OidcClientConfig.
        if let state = message.state { oidcConfig.state = state }
        if let nonce = message.nonce { oidcConfig.nonce = nonce }
        if let uiLocales = message.uiLocales { oidcConfig.uiLocales = uiLocales }
        if let refreshThreshold = message.refreshThreshold { oidcConfig.refreshThreshold = refreshThreshold }
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
        if let par = message.par { oidcConfig.par = par }
    }

    /// Applies every flat field of `handle` onto `oidcConfig`. Mirrors `ping_journey`'s
    /// `applyHandleFields`.
    static func applyHandleFields(_ handle: OidcConfigHandle, to oidcConfig: OidcClientConfig) {
        oidcConfig.clientId = handle.clientId
        if let discoveryEndpoint = handle.discoveryEndpoint { oidcConfig.discoveryEndpoint = discoveryEndpoint }
        if let openId = handle.openId {
            applyOpenId(
                to: oidcConfig,
                discovered: handle.discoveryEndpoint != nil,
                authorizationEndpoint: openId.authorizationEndpoint,
                tokenEndpoint: openId.tokenEndpoint,
                userinfoEndpoint: openId.userinfoEndpoint,
                endSessionEndpoint: openId.endSessionEndpoint,
                pingEndIdpSessionEndpoint: openId.pingEndIdpSessionEndpoint,
                revocationEndpoint: openId.revocationEndpoint
            )
        }
        if let redirectUri = handle.redirectUri { oidcConfig.redirectUri = redirectUri }
        if !handle.scopes.isEmpty { oidcConfig.scopes = Set(handle.scopes) }
        if let acrValues = handle.acrValues { oidcConfig.acrValues = acrValues }
        // signOutRedirectUri: no equivalent field on iOS's OidcClientConfig.
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

    /// Without discovery, sets `openId` directly, which skips discovery. With it, patches the
    /// discovered document instead, so endpoints the explicit set doesn't carry (e.g. PAR) still
    /// come from discovery. Same rule as `ping_oidc` and `ping_journey`, on both platforms.
    private static func applyOpenId(
        to oidcConfig: OidcClientConfig,
        discovered: Bool,
        authorizationEndpoint: String,
        tokenEndpoint: String,
        userinfoEndpoint: String,
        endSessionEndpoint: String?,
        pingEndIdpSessionEndpoint: String?,
        revocationEndpoint: String?
    ) {
        guard discovered else {
            oidcConfig.openId = OpenIdConfiguration(
                authorizationEndpoint: authorizationEndpoint,
                tokenEndpoint: tokenEndpoint,
                userinfoEndpoint: userinfoEndpoint,
                endSessionEndpoint: endSessionEndpoint ?? "",
                revocationEndpoint: revocationEndpoint ?? "",
                pingEndsessionEndpoint: pingEndIdpSessionEndpoint
            )
            return
        }
        oidcConfig.openIdOverride = { document in
            document.authorizationEndpoint = authorizationEndpoint
            document.tokenEndpoint = tokenEndpoint
            document.userinfoEndpoint = userinfoEndpoint
            if let endSessionEndpoint { document.endSessionEndpoint = endSessionEndpoint }
            if let revocationEndpoint { document.revocationEndpoint = revocationEndpoint }
            if let pingEndIdpSessionEndpoint { document.pingEndsessionEndpoint = pingEndIdpSessionEndpoint }
        }
    }

    private static func isBlank(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }
}
