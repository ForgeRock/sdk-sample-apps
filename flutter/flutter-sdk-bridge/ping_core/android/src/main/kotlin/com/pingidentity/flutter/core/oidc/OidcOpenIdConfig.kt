/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.oidc

/**
 * Explicit OpenID endpoint configuration, used in place of a discovery document.
 *
 * Core-owned mirror of both native SDKs' `OpenIdConfiguration`, narrowed to the fields needed to
 * skip discovery — PAR and device-flow endpoints are out of scope for this seam.
 */
data class OidcOpenIdConfig(
    /** The authorization endpoint URL. */
    val authorizationEndpoint: String,
    /** The token endpoint URL. */
    val tokenEndpoint: String,
    /** The userinfo endpoint URL. */
    val userinfoEndpoint: String,
    /** The end-session endpoint URL, if the provider supports RP-initiated logout. */
    val endSessionEndpoint: String? = null,
    /** The Ping end-IDP-session endpoint URL, using just the id token. */
    val pingEndIdpSessionEndpoint: String? = null,
    /** The token revocation endpoint URL. */
    val revocationEndpoint: String? = null,
)
