/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.oidc.OidcConfigHandle
import com.pingidentity.flutter.core.oidc.OidcOpenIdConfig
import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.oidc.OidcClient

/**
 * Wraps a live native [OidcClient] plus the flat [OidcConfigMessage] it was built from, so it can
 * be stored in [CoreRuntime.oidcClientRegistry] and read back through [OidcConfigHandle] by
 * consumers with no compile-time dependency on `ping_oidc` (e.g. `ping_journey`'s Phase 6
 * delegation).
 */
internal class OidcClientHandle(
    val payload: OidcConfigMessage,
    val client: OidcClient,
) : NativeHandle, OidcConfigHandle {
    override val clientId: String get() = payload.clientId
    override val discoveryEndpoint: String? get() = payload.discoveryEndpoint
    override val openId: OidcOpenIdConfig?
        get() =
            payload.openId?.let {
                OidcOpenIdConfig(
                    authorizationEndpoint = it.authorizationEndpoint,
                    tokenEndpoint = it.tokenEndpoint,
                    userinfoEndpoint = it.userinfoEndpoint,
                    endSessionEndpoint = it.endSessionEndpoint,
                    pingEndIdpSessionEndpoint = it.pingEndIdpSessionEndpoint,
                    revocationEndpoint = it.revocationEndpoint,
                )
            }
    override val redirectUri: String? get() = payload.redirectUri
    override val scopes: List<String> get() = payload.scopes?.filterNotNull() ?: emptyList()
    override val acrValues: String? get() = payload.acrValues
    override val signOutRedirectUri: String? get() = payload.signOutRedirectUri
    override val state: String? get() = payload.state
    override val nonce: String? get() = payload.nonce
    override val uiLocales: String? get() = payload.uiLocales
    override val refreshThreshold: Long? get() = payload.refreshThresholdSeconds
    override val loginHint: String? get() = payload.loginHint
    override val display: String? get() = payload.display
    override val prompt: String? get() = payload.prompt
    override val additionalParameters: Map<String, String>
        get() =
            payload.additionalParameters
                ?.entries
                ?.filter { it.key != null && it.value != null }
                ?.associate { it.key!! to it.value!! } ?: emptyMap()
    override val par: Boolean get() = payload.par
}

/**
 * Builds a native [OidcClient] from an [OidcConfigMessage] and registers it in the shared core
 * registry, returning the generated handle id.
 */
internal object OidcClientFactory {
    fun create(config: OidcConfigMessage): String {
        val nativeConfig = OidcConfigParser.parse(config)
        val client = OidcClient(nativeConfig)
        return CoreRuntime.oidcClientRegistry.register(OidcClientHandle(config, client))
    }
}
