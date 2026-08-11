/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.core.oidc

import com.pingidentity.flutter.core.registry.NativeHandle

/**
 * A [NativeHandle] exposing the flat configuration of a native OIDC client.
 *
 * Declared here, in `ping_core`, so that a module holding only an id into
 * [com.pingidentity.flutter.core.CoreRuntime.oidcClientRegistry] (such as `ping_journey`) can read
 * an OIDC client's configuration without a compile-time dependency on the OIDC native SDK.
 * Implementations live in `ping_oidc`, where the real client is constructed; consumers resolve
 * the registry entry and cast to this interface at runtime.
 */
interface OidcConfigHandle : NativeHandle {
    /** The OAuth2/OIDC client id. */
    val clientId: String

    /** The discovery endpoint URL, if discovery is used instead of an explicit [openId]. */
    val discoveryEndpoint: String?

    /** The explicit OpenID endpoint configuration, if discovery is not used. */
    val openId: OidcOpenIdConfig?

    /** The redirect URI registered for this client. */
    val redirectUri: String?

    /** OAuth2 scopes requested during authorization. */
    val scopes: List<String>

    /** The `acr_values` authorization parameter. */
    val acrValues: String?

    /** The sign-out redirect URI. Applied on Android only — no equivalent field on iOS. */
    val signOutRedirectUri: String?

    /** The `state` authorization parameter. */
    val state: String?

    /** The `nonce` authorization parameter. */
    val nonce: String?

    /** The `ui_locales` authorization parameter. */
    val uiLocales: String?

    /** Token refresh threshold, in seconds. `null` if unset (native applies its own default). */
    val refreshThreshold: Long?

    /** The `login_hint` authorization parameter. */
    val loginHint: String?

    /** The `display` authorization parameter. */
    val display: String?

    /** The `prompt` authorization parameter. */
    val prompt: String?

    /** Additional authorization parameters. */
    val additionalParameters: Map<String, String>

    /** Whether to use Pushed Authorization Requests (RFC 9126). */
    val par: Boolean
}
