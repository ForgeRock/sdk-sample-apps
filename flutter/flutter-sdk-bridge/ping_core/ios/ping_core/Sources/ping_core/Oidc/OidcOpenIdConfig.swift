/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation

/// Explicit OpenID endpoint configuration, used in place of a discovery document.
///
/// Core-owned mirror of both native SDKs' `OpenIdConfiguration`, narrowed to the fields needed to
/// skip discovery — PAR and device-flow endpoints are out of scope for this seam.
public struct OidcOpenIdConfig: Sendable {
    /// The authorization endpoint URL.
    public let authorizationEndpoint: String
    /// The token endpoint URL.
    public let tokenEndpoint: String
    /// The userinfo endpoint URL.
    public let userinfoEndpoint: String
    /// The end-session endpoint URL, if the provider supports RP-initiated logout.
    public let endSessionEndpoint: String?
    /// The Ping end-IDP-session endpoint URL, using just the id token.
    public let pingEndIdpSessionEndpoint: String?
    /// The token revocation endpoint URL.
    public let revocationEndpoint: String?

    /// Creates an explicit OpenID endpoint configuration.
    public init(
        authorizationEndpoint: String,
        tokenEndpoint: String,
        userinfoEndpoint: String,
        endSessionEndpoint: String? = nil,
        pingEndIdpSessionEndpoint: String? = nil,
        revocationEndpoint: String? = nil
    ) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.userinfoEndpoint = userinfoEndpoint
        self.endSessionEndpoint = endSessionEndpoint
        self.pingEndIdpSessionEndpoint = pingEndIdpSessionEndpoint
        self.revocationEndpoint = revocationEndpoint
    }
}
