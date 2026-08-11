/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingOidc
import ping_core

/// Wraps a live native `OidcClient` plus the flat `OidcConfigMessage` it was built from, so it
/// can be stored in `CoreRuntime.oidcClientRegistry` and read back through `OidcConfigHandle` by
/// consumers with no compile-time dependency on `ping_oidc`. `@unchecked Sendable` because
/// `OidcClient` is not itself `Sendable` — mirrors `ping_journey`'s `JourneyHandle`.
final class OidcClientHandle: NativeHandle, OidcConfigHandle, @unchecked Sendable {
    let payload: OidcConfigMessage
    let client: OidcClient

    init(payload: OidcConfigMessage, client: OidcClient) {
        self.payload = payload
        self.client = client
    }

    var clientId: String { payload.clientId }
    var discoveryEndpoint: String? { payload.discoveryEndpoint }
    var openId: OidcOpenIdConfig? {
        guard let openId = payload.openId else { return nil }
        return OidcOpenIdConfig(
            authorizationEndpoint: openId.authorizationEndpoint,
            tokenEndpoint: openId.tokenEndpoint,
            userinfoEndpoint: openId.userinfoEndpoint,
            endSessionEndpoint: openId.endSessionEndpoint,
            pingEndIdpSessionEndpoint: openId.pingEndIdpSessionEndpoint,
            revocationEndpoint: openId.revocationEndpoint
        )
    }
    var redirectUri: String? { payload.redirectUri }
    var scopes: [String] { payload.scopes?.compactMap { $0 } ?? [] }
    var acrValues: String? { payload.acrValues }
    var signOutRedirectUri: String? { nil }  // no such property on iOS's OidcClientConfig
    var state: String? { payload.state }
    var nonce: String? { payload.nonce }
    var uiLocales: String? { payload.uiLocales }
    var refreshThreshold: Int64? { payload.refreshThresholdSeconds }
    var loginHint: String? { payload.loginHint }
    var display: String? { payload.display }
    var prompt: String? { payload.prompt }
    var additionalParameters: [String: String] {
        payload.additionalParameters?.reduce(into: [String: String]()) { result, entry in
            if let key = entry.key, let value = entry.value { result[key] = value }
        } ?? [:]
    }
    var par: Bool { payload.par }
}

/// Builds a native `OidcClient` from an `OidcConfigMessage` and registers it in the shared core
/// registry, returning the generated handle id.
enum OidcClientFactory {
    static func create(_ config: OidcConfigMessage) async throws -> String {
        let nativeConfig = try OidcConfigParser.parse(config)
        let client = OidcClient(config: nativeConfig)
        let handle = OidcClientHandle(payload: config, client: client)
        return await CoreRuntime.oidcClientRegistry.register(handle)
    }
}
