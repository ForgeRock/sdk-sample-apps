/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci

import com.pingidentity.davinci.DaVinci
import com.pingidentity.davinci.module.Oidc
import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.oidc.OidcConfigHandle
import com.pingidentity.logger.Logger
import com.pingidentity.logger.NONE
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.OidcClientConfig
import com.pingidentity.oidc.OpenIdConfiguration
import com.pingidentity.orchestrate.Workflow

/**
 * Builds a native DaVinci [Workflow] from the flat, wire-serializable [DaVinciConfigMessage].
 *
 * The OIDC module is configured from exactly one source: the hoisted message fields, or a handle
 * resolved from `ping_core`'s `CoreRuntime.oidcClientRegistry` via
 * [DaVinciConfigMessage.oidcClientId]. [validate] enforces that before anything is built.
 */
internal object DaVinciConfigParser {
    /**
     * Applied when [DaVinciConfigMessage.timeoutMillis] is unset. Both native SDKs default to 15s
     * for DaVinci; passing it explicitly keeps the platforms aligned if either default moves.
     */
    const val DEFAULT_TIMEOUT_MILLIS = 15_000L

    fun parse(config: DaVinciConfigMessage): Workflow {
        validate(config)
        val handle = config.oidcClientId?.let { resolveOidcHandle(it) }
        return DaVinci {
            timeout = config.timeoutMillis ?: DEFAULT_TIMEOUT_MILLIS
            // Logger.NONE by default (the native default). STANDARD routes every SDK
            // request/response to logcat, which can surface token material, so it is opt-in.
            logger =
                when (config.logLevel) {
                    DaVinciLogLevel.STANDARD -> Logger.STANDARD
                    else -> Logger.NONE
                }
            module(Oidc) {
                if (handle != null) applyHandle(handle) else applyMessage(config)
            }
        }
    }
}

/**
 * Throws [IllegalArgumentException] unless [config] configures OIDC through exactly one path:
 * [DaVinciConfigMessage.oidcClientId], or the hoisted fields with a `clientId`, a `redirectUri`,
 * and a `discoveryEndpoint` or `openId`. Top-level so unit tests can call it without building a
 * native `DaVinci`, whose builder reads `android.os.LocaleList` and can't run on the plain JVM.
 */
internal fun validate(config: DaVinciConfigMessage) {
    val hasInline = hasInlineOidcFields(config)
    if (config.oidcClientId != null) {
        require(!hasInline) {
            "DaVinciConfigMessage.oidcClientId cannot be combined with any inline OIDC field — " +
                "configure OIDC through exactly one path."
        }
        return
    }
    require(!config.clientId.isNullOrBlank()) {
        "DaVinciConfigMessage requires clientId, or oidcClientId to reuse a configured OIDC client."
    }
    require(!config.redirectUri.isNullOrBlank()) { "DaVinciConfigMessage requires redirectUri." }
    require(!config.discoveryEndpoint.isNullOrBlank() || config.openId != null) {
        "DaVinciConfigMessage requires discoveryEndpoint or openId."
    }
}

/** Whether [config] sets any hoisted OIDC field — every one, so none is silently dropped. */
internal fun hasInlineOidcFields(config: DaVinciConfigMessage): Boolean =
    config.clientId != null ||
        config.discoveryEndpoint != null ||
        config.openId != null ||
        config.redirectUri != null ||
        config.scopes != null ||
        config.acrValues != null ||
        config.signOutRedirectUri != null ||
        config.state != null ||
        config.nonce != null ||
        config.uiLocales != null ||
        config.refreshThreshold != null ||
        config.loginHint != null ||
        config.display != null ||
        config.prompt != null ||
        config.additionalParameters != null ||
        config.par != null

/**
 * Resolves [oidcClientId] from `ping_core`'s shared `CoreRuntime.oidcClientRegistry`, and
 * validates it exposes a usable configuration. Same rule as `ping_journey`'s `resolveOidcHandle`.
 */
internal fun resolveOidcHandle(oidcClientId: String): OidcConfigHandle {
    val handle =
        CoreRuntime.oidcClientRegistry.resolve(oidcClientId) as? OidcConfigHandle
            ?: throw IllegalArgumentException("OIDC client instance not found for id=$oidcClientId")
    if (handle.discoveryEndpoint?.trim().isNullOrEmpty() && handle.openId == null) {
        throw IllegalArgumentException(
            "OIDC client id=$oidcClientId does not expose discoveryEndpoint or openId. " +
                "Configure OIDC with discoveryEndpoint or openId before composing DaVinci."
        )
    }
    return handle
}

/**
 * Applies the hoisted OIDC fields of [config] onto this [OidcClientConfig]. Mirrors `ping_oidc`'s
 * `applyMessage`. Not shared through `ping_core`: that module has no native SDK dependency, and
 * `OidcClientConfig` is an SDK type.
 */
internal fun OidcClientConfig.applyMessage(config: DaVinciConfigMessage) {
    config.clientId?.let { clientId = it }
    config.redirectUri?.let { redirectUri = it }
    // TODO: Remove once the SDK fixes it. `OidcClientConfig.clone()` reads the lateinit
    // `discoveryEndpoint` unconditionally, so openId-only configs crash on authorize. The empty
    // value is never fetched while `openId` is set.
    discoveryEndpoint = config.discoveryEndpoint ?: ""
    config.openId?.let {
        applyOpenId(
            discovered = config.discoveryEndpoint != null,
            authorizationEndpoint = it.authorizationEndpoint,
            tokenEndpoint = it.tokenEndpoint,
            userinfoEndpoint = it.userinfoEndpoint,
            endSessionEndpoint = it.endSessionEndpoint,
            pingEndIdpSessionEndpoint = it.pingEndIdpSessionEndpoint,
            revocationEndpoint = it.revocationEndpoint,
        )
    }
    config.scopes?.let { scopes = it.filterNotNull().toMutableSet() }
    config.acrValues?.let { acrValues = it }
    // Android-only — no equivalent field on iOS's OidcClientConfig.
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
    config.par?.let { par = it }
}

/**
 * Applies every flat field of [handle] onto this [OidcClientConfig]. Mirrors `ping_journey`'s
 * `applyHandle`, for the same reason [applyMessage] is not shared through `ping_core`.
 */
internal fun OidcClientConfig.applyHandle(handle: OidcConfigHandle) {
    clientId = handle.clientId
    // Same SDK workaround as in applyMessage.
    discoveryEndpoint = handle.discoveryEndpoint ?: ""
    handle.openId?.let {
        applyOpenId(
            discovered = handle.discoveryEndpoint != null,
            authorizationEndpoint = it.authorizationEndpoint,
            tokenEndpoint = it.tokenEndpoint,
            userinfoEndpoint = it.userinfoEndpoint,
            endSessionEndpoint = it.endSessionEndpoint,
            pingEndIdpSessionEndpoint = it.pingEndIdpSessionEndpoint,
            revocationEndpoint = it.revocationEndpoint,
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

/**
 * Without discovery, sets `openId` directly, which skips discovery. With it, patches the
 * discovered document instead, so endpoints the explicit set doesn't carry (e.g. PAR) still come
 * from discovery. Same rule as `ping_oidc` and `ping_journey`, on both platforms.
 */
private fun OidcClientConfig.applyOpenId(
    discovered: Boolean,
    authorizationEndpoint: String,
    tokenEndpoint: String,
    userinfoEndpoint: String,
    endSessionEndpoint: String?,
    pingEndIdpSessionEndpoint: String?,
    revocationEndpoint: String?,
) {
    if (!discovered) {
        openId =
            OpenIdConfiguration(
                authorizationEndpoint = authorizationEndpoint,
                tokenEndpoint = tokenEndpoint,
                userinfoEndpoint = userinfoEndpoint,
                endSessionEndpoint = endSessionEndpoint ?: "",
                pingEndIdpSessionEndpoint = pingEndIdpSessionEndpoint ?: "",
                revocationEndpoint = revocationEndpoint ?: "",
            )
        return
    }
    openIdOverride = {
        this.authorizationEndpoint = authorizationEndpoint
        this.tokenEndpoint = tokenEndpoint
        this.userinfoEndpoint = userinfoEndpoint
        endSessionEndpoint?.let { this.endSessionEndpoint = it }
        pingEndIdpSessionEndpoint?.let { this.pingEndIdpSessionEndpoint = it }
        revocationEndpoint?.let { this.revocationEndpoint = it }
    }
}
