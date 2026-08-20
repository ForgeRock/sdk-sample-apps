/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import com.pingidentity.browser.BrowserCanceledException
import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.mapper.JsonBridgeMapper
import com.pingidentity.flutter.oidc.error.OidcErrorCodes
import com.pingidentity.flutter.oidc.error.OidcErrorMapper
import com.pingidentity.flutter.oidc.error.classifyError
import com.pingidentity.oidc.OidcError
import com.pingidentity.oidc.Token
import com.pingidentity.oidc.User
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import com.pingidentity.utils.Result as OidcResult

/**
 * Implements the generated [PingOidcHostApi]. `configureOidc`/`dispose` (Phase 2),
 * `createWebClient`/`authorize`/`hasUser` (Phase 3), and `token`/`refresh`/`userInfo`/`revoke`/
 * `signOff` (Phase 4) all have real bodies now.
 */
class OidcHostApiImpl : PingOidcHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun configureOidc(config: OidcConfigMessage, callback: (Result<String>) -> Unit) {
        callback(
            runCatching { OidcClientFactory.create(config) }
                .classifyError(OidcErrorCodes.CONFIGURE)
        )
    }

    override fun createWebClient(
        clientId: String,
        options: BrowserOptionsMessage?,
        callback: (Result<String>) -> Unit
    ) {
        callback(
            runCatching { OidcWebClientFactory.create(clientId, options) }
                .classifyError(OidcErrorCodes.CREATE_WEB_CLIENT)
        )
    }

    override fun authorize(webClientId: String, callback: (Result<AuthorizeResultMessage>) -> Unit) {
        // Custom Tab launch needs the main thread and differs from
        // this class's other calls, which run on Dispatchers.IO.
        scope.launch(Dispatchers.Main) {
            val outcome =
                runCatching { resolveWebClientHandle(webClientId).webClient.authorize() }
                    .fold(
                        onSuccess = { authorizeResult ->
                            authorizeResult.fold(
                                onSuccess = {
                                    Result.success(AuthorizeResultMessage(AuthorizeResultType.SUCCESS))
                                },
                                onFailure = { cause -> mapAuthorizeFailure(cause) },
                            )
                        },
                        onFailure = { error -> mapAuthorizeFailure(error) },
                    )
            callback(outcome)
        }
    }

    /**
     * A cancelled Custom Tab must resolve [AuthorizeResultMessage.type] as `cancel`, not surface
     * as a thrown/classified error — this check runs before [OidcErrorMapper] so cancellation
     * never reaches it.
     */
    private fun mapAuthorizeFailure(cause: Throwable): Result<AuthorizeResultMessage> =
        if (cause is BrowserCanceledException) {
            Result.success(AuthorizeResultMessage(AuthorizeResultType.CANCEL))
        } else {
            Result.failure(OidcErrorMapper.fromThrowable(OidcErrorCodes.AUTHORIZE, cause))
        }

    override fun hasUser(webClientId: String, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            val result =
                runCatching { resolveWebClientHandle(webClientId).webClient.user() != null }
            callback(result.classifyError(OidcErrorCodes.HAS_USER))
        }
    }

    override fun token(webClientId: String, callback: (Result<TokenMessage>) -> Unit) {
        scope.launch {
            callback(fetchToken(webClientId, OidcErrorCodes.TOKEN) { it.token() })
        }
    }

    override fun refresh(webClientId: String, callback: (Result<TokenMessage>) -> Unit) {
        // Go through `User.refresh()` on both platforms, not `OidcClient.refresh()` — iOS has no
        // equivalent, so this keeps one code shape (see IMPLEMENTATION_PLAN_OIDC.md § Platform
        // asymmetries).
        scope.launch {
            callback(fetchToken(webClientId, OidcErrorCodes.REFRESH) { it.refresh() })
        }
    }

    /** Shared body for [token]/[refresh]: resolve the user, call [tokenCall], map the result. */
    private suspend fun fetchToken(
        webClientId: String,
        code: String,
        tokenCall: suspend (User) -> OidcResult<Token, OidcError>,
    ): Result<TokenMessage> =
        runCatching { resolveUser(webClientId) }
            .fold(
                onSuccess = { user ->
                    when (val result = tokenCall(user)) {
                        is OidcResult.Success -> Result.success(result.value.toMessage())
                        is OidcResult.Failure ->
                            Result.failure(OidcErrorMapper.fromOidcError(code, result.value))
                    }
                },
                onFailure = { error -> Result.failure(OidcErrorMapper.fromThrowable(code, error)) },
            )

    override fun userInfo(
        webClientId: String,
        cache: Boolean,
        callback: (Result<Map<String?, Any?>>) -> Unit
    ) {
        scope.launch {
            val outcome =
                runCatching { resolveUser(webClientId) }
                    .fold(
                        onSuccess = { user ->
                            // `cache` is always passed through explicitly — Android's own default
                            // is `false`, iOS's is `true`; never rely on either platform default.
                            when (val result = user.userinfo(cache)) {
                                is OidcResult.Success -> {
                                    val flattened =
                                        JsonBridgeMapper.encodeJsonElement(result.value)
                                            as? Map<String?, Any?> ?: emptyMap()
                                    Result.success(flattened)
                                }
                                is OidcResult.Failure ->
                                    Result.failure(
                                        OidcErrorMapper.fromOidcError(OidcErrorCodes.USERINFO, result.value)
                                    )
                            }
                        },
                        onFailure = { error ->
                            Result.failure(OidcErrorMapper.fromThrowable(OidcErrorCodes.USERINFO, error))
                        },
                    )
            callback(outcome)
        }
    }

    override fun revoke(webClientId: String, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            val outcome = runCatching { resolveUser(webClientId).revoke() }
                .classifyError(OidcErrorCodes.REVOKE)
            callback(outcome)
        }
    }

    override fun signOff(webClientId: String, callback: (Result<Boolean>) -> Unit) {
        // Known SDK gap (see IMPLEMENTATION_PLAN_OIDC.md Phase 4): the only reachable sign-off
        // path from a web-client id is `User.logout()`, which returns `Unit` and discards the
        // underlying `Workflow.signOff()` result — the boolean-returning `OidcClient.endSession()`
        // is not reachable here. `true` below means "logout completed without a bridge-level
        // exception," not "a session existed and was terminated."
        scope.launch {
            val outcome =
                runCatching { resolveUser(webClientId).logout() }
                    .fold(
                        onSuccess = { Result.success(true) },
                        onFailure = { error ->
                            Result.failure(OidcErrorMapper.fromThrowable(OidcErrorCodes.SIGN_OFF, error))
                        },
                    )
            callback(outcome)
        }
    }

    override fun dispose(handleId: String, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            // A dispose call may target either a client handle or a web-client handle; removal is
            // a no-op on an unknown id in both registries (SimpleRegistry.remove), so trying both
            // unconditionally is safe and avoids tracking which registry a given id came from.
            val result =
                runCatching {
                    CoreRuntime.oidcClientRegistry.remove(handleId)
                    CoreRuntime.oidcWebClientRegistry.remove(handleId)
                }
            callback(result.classifyError(OidcErrorCodes.DISPOSE))
        }
    }

    private fun resolveWebClientHandle(webClientId: String): OidcWebClientHandle =
        (CoreRuntime.oidcWebClientRegistry.resolve(webClientId) as? OidcWebClientHandle)
            ?: throw IllegalStateException(
                "OIDC web client instance not found for id=$webClientId"
            )

    /** Resolves [webClientId] to a live [User], or throws if no session exists yet. */
    private suspend fun resolveUser(webClientId: String): User =
        resolveWebClientHandle(webClientId).webClient.user()
            ?: throw IllegalStateException("No OIDC user session for id=$webClientId")

    /** Cancels all in-flight coroutines. Called from [PingOidcPlugin.onDetachedFromEngine]. */
    fun shutdown() {
        scope.cancel()
    }
}

/** Maps a native [Token] onto the bridge's [TokenMessage] — fields match 1:1; `expireAt` (native's
 * internal expiry stamp) has no [TokenMessage] counterpart and is dropped. */
private fun Token.toMessage(): TokenMessage =
    TokenMessage(
        accessToken = accessToken,
        tokenType = tokenType,
        scope = scope,
        expiresIn = expiresIn,
        refreshToken = refreshToken,
        idToken = idToken,
    )
