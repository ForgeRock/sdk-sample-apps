/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc

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

            if (hasOidcConfig(config)) {
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
        config.clientId != null ||
            config.discoveryEndpoint != null ||
            config.redirectUri != null ||
            config.scopes != null
}
