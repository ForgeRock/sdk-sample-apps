/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// A `NativeHandle` exposing the flat configuration of a native OIDC client.
///
/// Declared here, in `ping_core`, so that a module holding only an id into
/// `CoreRuntime.oidcClientRegistry` (such as `ping_journey`) can read an OIDC client's
/// configuration without a compile-time dependency on the OIDC native SDK. Implementations live
/// in `ping_oidc`, where the real client is constructed; consumers resolve the registry entry and
/// cast to this protocol at runtime.
public protocol OidcConfigHandle: NativeHandle {
    /// The OAuth2/OIDC client id.
    var clientId: String { get }

    /// The discovery endpoint URL, if discovery is used instead of an explicit `openId`.
    var discoveryEndpoint: String? { get }

    /// The explicit OpenID endpoint configuration, if discovery is not used.
    var openId: OidcOpenIdConfig? { get }

    /// The redirect URI registered for this client.
    var redirectUri: String? { get }

    /// OAuth2 scopes requested during authorization.
    var scopes: [String] { get }

    /// The `acr_values` authorization parameter.
    var acrValues: String? { get }

    /// The sign-out redirect URI. Applied on Android only — no equivalent field on iOS.
    var signOutRedirectUri: String? { get }

    /// The `state` authorization parameter.
    var state: String? { get }

    /// The `nonce` authorization parameter.
    var nonce: String? { get }

    /// The `ui_locales` authorization parameter.
    var uiLocales: String? { get }

    /// Token refresh threshold, in seconds. `nil` if unset (native applies its own default).
    var refreshThreshold: Int64? { get }

    /// The `login_hint` authorization parameter.
    var loginHint: String? { get }

    /// The `display` authorization parameter.
    var display: String? { get }

    /// The `prompt` authorization parameter.
    var prompt: String? { get }

    /// Additional authorization parameters.
    var additionalParameters: [String: String] { get }

    /// Whether to use Pushed Authorization Requests (RFC 9126).
    var par: Bool { get }
}
