/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import com.pingidentity.oidc.OidcClientConfig
import com.pingidentity.oidc.OpenIdConfiguration

/**
 * Maps a flat [OidcConfigMessage] onto the native SDK's [OidcClientConfig].
 *
 * Neither native SDK validates at construction time whether a client can actually discover or
 * resolve an OpenID configuration (Android's `discoveryEndpoint`/`clientId`/`redirectUri` are
 * `lateinit var` with no init-time check; failure only surfaces lazily on first use). This parser
 * performs that validation itself so `configureOidc` fails fast with a typed error rather than a
 * bare `UninitializedPropertyAccessException` deep in a later call.
 */
internal object OidcConfigParser {
    fun parse(config: OidcConfigMessage): OidcClientConfig {
        require(config.discoveryEndpoint != null || config.openId != null) {
            "OidcConfigMessage must set either discoveryEndpoint or openId"
        }
        return OidcClientConfig().apply { applyMessage(config) }
    }
}

/**
 * Maps every flat field of [config] onto this [OidcClientConfig] receiver. Shared by
 * [OidcConfigParser.parse] (builds a standalone config) and [OidcWebClientFactory] (applies the
 * same fields inside a `module(Oidc) { }` block, which has the identical
 * `OidcClientConfig.() -> Unit` receiver type) so the field list can't drift between the two call
 * sites.
 */
internal fun OidcClientConfig.applyMessage(config: OidcConfigMessage) {
    clientId = config.clientId
    redirectUri = config.redirectUri
    config.discoveryEndpoint?.let { discoveryEndpoint = it }
    config.openId?.let {
        openId =
            OpenIdConfiguration(
                authorizationEndpoint = it.authorizationEndpoint,
                tokenEndpoint = it.tokenEndpoint,
                userinfoEndpoint = it.userinfoEndpoint,
                endSessionEndpoint = it.endSessionEndpoint ?: "",
                pingEndIdpSessionEndpoint = it.pingEndIdpSessionEndpoint ?: "",
                revocationEndpoint = it.revocationEndpoint ?: "",
            )
    }
    config.scopes?.let { scopes = it.filterNotNull().toMutableSet() }
    config.acrValues?.let { acrValues = it }
    // Android-only — no equivalent field on iOS's OidcClientConfig at 2.1.0.
    config.signOutRedirectUri?.let { signOutRedirectUri = it }
    config.state?.let { state = it }
    config.nonce?.let { nonce = it }
    config.uiLocales?.let { uiLocales = it }
    config.refreshThresholdSeconds?.let { refreshThreshold = it }
    config.loginHint?.let { loginHint = it }
    config.display?.let { display = it }
    config.prompt?.let { prompt = it }
    config.additionalParameters?.let { params ->
        additionalParameters =
            params.entries
                .filter { it.key != null && it.value != null }
                .associate { it.key!! to it.value!! }
    }
    par = config.par
}
