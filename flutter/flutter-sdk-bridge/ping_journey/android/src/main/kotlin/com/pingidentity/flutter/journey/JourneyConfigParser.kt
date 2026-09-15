/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.oidc.OidcConfigHandle
import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.OidcClientConfig
import com.pingidentity.oidc.OpenIdConfiguration

/**
 * Builds a native [Journey] from the flat, wire-serializable [JourneyConfigMessage].
 *
 * Trimmed to the fields the Pigeon schema carries (no storage/logger handle registries yet —
 * those arrive with a future module). `realm`/`cookie` are left unset when absent so the native
 * SDK's own defaults (`realm = "root"`, `cookie = "iPlanetDirectoryPro"`) apply.
 */
internal object JourneyConfigParser {
    /**
     * Explicit cross-platform default when [JourneyConfigMessage.timeoutMillis] is unset — the
     * native SDKs' own defaults diverge (Android 15s, iOS 30s), which otherwise makes the same
     * unset config wait a different duration per platform with no indication in code or docs.
     */
    const val DEFAULT_TIMEOUT_MILLIS = 30_000L

    fun parse(config: JourneyConfigMessage): Journey =
        Journey {
            serverUrl = config.serverUrl
            config.realm?.let { realm = it }
            config.cookie?.let { cookie = it }
            timeout = config.timeoutMillis ?: DEFAULT_TIMEOUT_MILLIS
            // The SDK's global default is Logger.NONE (a no-op), which also suppresses Ktor's
            // HTTP Logging plugin — every SDK request/response, including the headless OIDC
            // authorize exchange, then produces no logcat output at all. STANDARD routes through
            // android.util.Log under the "Ping SDK <version>" tag. Diagnostic aid, not a
            // production setting: flip to Logger.NONE once the flow is verified.
            logger = Logger.STANDARD

            val oidcClientId = config.oidcClientId
            if (oidcClientId != null) {
                module(Oidc) { applyHandle(resolveOidcHandle(oidcClientId)) }
            } else if (hasOidcConfig(config)) {
                module(Oidc) {
                    config.clientId?.let { clientId = it }
                    config.discoveryEndpoint?.let { discoveryEndpoint = it }
                    config.redirectUri?.let { redirectUri = it }
                    config.scopes?.let { scopes = it.filterNotNull().toMutableSet() }
                    config.acrValues?.let { acrValues = it }
                    config.signOutRedirectUri?.let { signOutRedirectUri = it }
                    config.state?.let { state = it }
                    config.nonce?.let { nonce = it }
                    config.uiLocales?.let { uiLocales = it }
                    config.refreshThreshold?.let { refreshThreshold = it }
                    config.loginHint?.let { loginHint = it }
                    config.display?.let { display = it }
                    config.prompt?.let { prompt = it }
                    config.additionalParameters?.let { params ->
                        additionalParameters =
                            params.entries.filter { it.key != null && it.value != null }
                                .associate { it.key!! to it.value!! }
                    }
                }
            }
        }

    fun hasOidcConfig(config: JourneyConfigMessage): Boolean =
        config.oidcClientId != null ||
            config.clientId != null ||
            config.discoveryEndpoint != null ||
            config.redirectUri != null ||
            config.scopes != null
}

/**
 * Resolves [oidcClientId] from `ping_core`'s shared `CoreRuntime.oidcClientRegistry`, and
 * validates it exposes a usable configuration. Top-level (rather than a member of
 * [JourneyConfigParser]) so unit tests can call it directly — calling it through
 * [JourneyConfigParser.parse] would otherwise require constructing a full native `Journey`, which
 * is not viable in a plain JVM unit test (`Journey.kt`'s own builder reads
 * `android.os.LocaleList.getDefault()` internally, unrelated to this phase, which the stub
 * `android.jar` can't satisfy).
 */
internal fun resolveOidcHandle(oidcClientId: String): OidcConfigHandle {
    val handle =
        CoreRuntime.oidcClientRegistry.resolve(oidcClientId) as? OidcConfigHandle
            ?: throw IllegalArgumentException("OIDC client instance not found for id=$oidcClientId")
    val discoveryEndpoint = handle.discoveryEndpoint?.trim()
    if (discoveryEndpoint.isNullOrEmpty() && handle.openId == null) {
        throw IllegalArgumentException(
            "OIDC client id=$oidcClientId does not expose discoveryEndpoint or openId. " +
                "Configure OIDC with discoveryEndpoint or openId before composing Journey."
        )
    }
    return handle
}

/**
 * Applies every flat field of [handle] — resolved from `ping_core`'s shared
 * `CoreRuntime.oidcClientRegistry` — onto this [OidcClientConfig] receiver, in place of the
 * inline [JourneyConfigMessage] fields. Mirrors `ping_oidc`'s own `OidcConfigParser.applyMessage`
 * (also a top-level extension, for the same reason), so the field list can't drift between the
 * two paths.
 */
internal fun OidcClientConfig.applyHandle(handle: OidcConfigHandle) {
    clientId = handle.clientId
    handle.discoveryEndpoint?.let { discoveryEndpoint = it }
    handle.openId?.let {
        openId =
            OpenIdConfiguration(
                authorizationEndpoint = it.authorizationEndpoint,
                tokenEndpoint = it.tokenEndpoint,
                userinfoEndpoint = it.userinfoEndpoint,
                // Coercions: native SDK's OpenIdConfiguration requires non-null endpoints, but
                // ping_core's OidcOpenIdConfig leaves them nullable (mirrors ping_oidc's own
                // OidcConfigParser.applyMessage).
                endSessionEndpoint = it.endSessionEndpoint ?: "",
                pingEndIdpSessionEndpoint = it.pingEndIdpSessionEndpoint ?: "",
                revocationEndpoint = it.revocationEndpoint ?: "",
            )
    }
    handle.redirectUri?.let { redirectUri = it }
    if (handle.scopes.isNotEmpty()) scopes = handle.scopes.toMutableSet()
    handle.acrValues?.let { acrValues = it }
    handle.signOutRedirectUri?.let { signOutRedirectUri = it }
    handle.state?.let { state = it }
    handle.nonce?.let { nonce = it }
    handle.uiLocales?.let { uiLocales = it }
    handle.refreshThreshold?.let { refreshThreshold = it }
    handle.loginHint?.let { loginHint = it }
    handle.display?.let { display = it }
    handle.prompt?.let { prompt = it }
    if (handle.additionalParameters.isNotEmpty()) additionalParameters = handle.additionalParameters
    par = handle.par
}
