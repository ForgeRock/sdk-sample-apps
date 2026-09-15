/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.mapper.JsonBridgeMapper
import com.pingidentity.flutter.journey.callback.JourneyCallbackValueApplier
import com.pingidentity.flutter.journey.error.JourneyErrorCodes
import com.pingidentity.flutter.journey.error.JourneyErrorMapper
import com.pingidentity.flutter.journey.error.classifyError
import com.pingidentity.flutter.journey.mapper.JourneyNodeMapper
import com.pingidentity.journey.start
import com.pingidentity.journey.user
import com.pingidentity.oidc.Token
import android.util.Log
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.utils.Result as PingResult
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/**
 * Implements the generated [PingJourneyHostApi]: `configureJourney`/`start` build the native
 * `Journey` and cache the current node per `journeyId`; `next()` applies submitted callback
 * values onto the cached [ContinueNode] and advances the flow.
 */
class JourneyHostApiImpl : PingJourneyHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** Most recent [ContinueNode] per journeyId, for future callback re-resolution. */
    private val continueNodeMap = ConcurrentHashMap<String, ContinueNode>()

    /** Serializes [next] per journeyId so a double-submit can't race two callback applications. */
    private val nextMutexes = ConcurrentHashMap<String, Mutex>()

    override fun configureJourney(
        config: JourneyConfigMessage,
        callback: (Result<String>) -> Unit
    ) {
        callback(
            runCatching { JourneyClientFactory.create(config) }
                .classifyError(JourneyErrorCodes.CONFIGURE)
        )
    }

    override fun start(
        journeyId: String,
        name: String,
        options: StartOptionsMessage,
        callback: (Result<NodeMessage>) -> Unit
    ) {
        scope.launch {
            val result = runCatching {
                val journey = resolveJourney(journeyId)
                val node = journey.start(name) {
                    forceAuth = options.forceAuth
                    noSession = options.noSession
                }
                setNode(journeyId, node)
                JourneyNodeMapper.map(node)
            }
            callback(result.classifyError(JourneyErrorCodes.START))
        }
    }

    override fun next(
        journeyId: String,
        values: List<CallbackValueMessage?>,
        callback: (Result<NodeMessage>) -> Unit
    ) {
        scope.launch {
            val mutex = nextMutexes.getOrPut(journeyId) { Mutex() }
            val result = mutex.withLock {
                runCatching {
                    val currentNode =
                        continueNodeMap[journeyId]
                            ?: throw IllegalStateException(
                                "No active ContinueNode found for journeyId=$journeyId"
                            )
                    JourneyCallbackValueApplier.apply(currentNode, values.filterNotNull())
                    val nextNode = currentNode.next()
                    setNode(journeyId, nextNode)
                    JourneyNodeMapper.map(nextNode)
                }
            }
            callback(result.classifyError(JourneyErrorCodes.NEXT))
        }
    }

    override fun getSession(journeyId: String, callback: (Result<SessionMessage?>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val handle = resolveHandle(journeyId)
                if (!handle.hasOidc) {
                    null
                } else {
                    val user = handle.journey.user()
                    if (user == null) {
                        null
                    } else {
                        when (val tokenResult = user.token()) {
                            is PingResult.Success -> {
                                val token = tokenResult.value as? Token
                                    ?: throw IllegalStateException("Invalid token payload type")
                                val userInfo = when (val uiResult = user.userinfo(false)) {
                                    is PingResult.Success -> {
                                        @Suppress("UNCHECKED_CAST")
                                        JsonBridgeMapper.encodeJsonElement(uiResult.value) as? Map<String?, Any?>
                                    }
                                    is PingResult.Failure -> {
                                        Log.w(
                                            TAG,
                                            "userinfo() failed for journeyId=$journeyId: ${uiResult.value}",
                                        )
                                        null
                                    }
                                }
                                SessionMessage(
                                    accessToken = token.accessToken,
                                    refreshToken = token.refreshToken,
                                    idToken = token.idToken,
                                    tokenType = token.tokenType,
                                    scope = token.scope,
                                    expiresIn = token.expiresIn,
                                    userInfo = userInfo,
                                )
                            }
                            is PingResult.Failure ->
                                throw JourneyErrorMapper.fromOidcError(
                                    JourneyErrorCodes.GET_SESSION,
                                    tokenResult.value
                                )
                        }
                    }
                }
            }
            callback(result.classifyError(JourneyErrorCodes.GET_SESSION))
        }
    }

    override fun refreshToken(journeyId: String, callback: (Result<SessionMessage>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val user = requireOidcUser(journeyId, operation = "refreshToken")
                when (val refreshResult = user.refresh()) {
                    is PingResult.Success -> {
                        val token = refreshResult.value as? Token
                            ?: throw IllegalStateException("Invalid token payload type")
                        // userInfo is deliberately null here — claims are fetched separately
                        // via getUserInfo, so callers keep whatever they already loaded.
                        SessionMessage(
                            accessToken = token.accessToken,
                            refreshToken = token.refreshToken,
                            idToken = token.idToken,
                            tokenType = token.tokenType,
                            scope = token.scope,
                            expiresIn = token.expiresIn,
                        )
                    }
                    is PingResult.Failure ->
                        throw JourneyErrorMapper.fromOidcError(
                            JourneyErrorCodes.REFRESH,
                            refreshResult.value
                        )
                }
            }
            callback(result.classifyError(JourneyErrorCodes.REFRESH))
        }
    }

    override fun revokeToken(journeyId: String, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val user = requireOidcUser(journeyId, operation = "revokeToken")
                // Native swallows server-side revocation errors, matching ping_oidc's revoke.
                user.revoke()
            }
            callback(result.classifyError(JourneyErrorCodes.REVOKE))
        }
    }

    override fun getUserInfo(
        journeyId: String,
        cache: Boolean,
        callback: (Result<Map<String?, Any?>>) -> Unit
    ) {
        scope.launch {
            val result = runCatching {
                val user = requireOidcUser(journeyId, operation = "getUserInfo")
                // cache is always passed explicitly — the native SDKs' own defaults differ
                // (Android false, iOS true).
                when (val uiResult = user.userinfo(cache)) {
                    is PingResult.Success ->
                        @Suppress("UNCHECKED_CAST")
                        (JsonBridgeMapper.encodeJsonElement(uiResult.value)
                            as? Map<String?, Any?>) ?: emptyMap<String?, Any?>()
                    is PingResult.Failure ->
                        throw JourneyErrorMapper.fromOidcError(
                            JourneyErrorCodes.USERINFO,
                            uiResult.value
                        )
                }
            }
            callback(result.classifyError(JourneyErrorCodes.USERINFO))
        }
    }

    /**
     * Resolves the OIDC user for the token-command methods, throwing a typed
     * state error when the Journey has no OIDC configuration or no user
     * session — unlike [getSession], which is a query and returns null instead
     * (null = "nothing to show"; a command must fail loudly).
     */
    private suspend fun requireOidcUser(journeyId: String, operation: String) =
        run {
            val handle = resolveHandle(journeyId)
            if (!handle.hasOidc) {
                throw IllegalStateException(
                    "$operation requires OIDC configuration; this Journey has none (journeyId=$journeyId)"
                )
            }
            handle
        }.let { handle ->
            handle.journey.user()
                ?: throw IllegalStateException(
                    "No user session for journeyId=$journeyId — complete the Journey first"
                )
        }

    override fun signOff(journeyId: String, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val handle = resolveHandle(journeyId)
                handle.journey.signOff().getOrThrow()
                if (handle.hasOidc) {
                    handle.journey.user()?.logout()
                }
                clearNodeState(journeyId)
                true
            }
            callback(result.classifyError(JourneyErrorCodes.SIGN_OFF))
        }
    }

    override fun dispose(journeyId: String, callback: (Result<Unit>) -> Unit) {
        callback(
            runCatching { removeJourney(journeyId) }.classifyError(JourneyErrorCodes.DISPOSE)
        )
    }

    private fun resolveJourney(journeyId: String) = resolveHandle(journeyId).journey

    private fun resolveHandle(journeyId: String): JourneyHandle =
        (CoreRuntime.journeyRegistry.resolve(journeyId) as? JourneyHandle)
            ?: throw IllegalStateException("Journey instance not found for id=$journeyId")

    private fun setNode(journeyId: String, node: Node) {
        if (node is ContinueNode) {
            continueNodeMap[journeyId] = node
        } else {
            continueNodeMap.remove(journeyId)
        }
    }

    private fun clearNodeState(journeyId: String) {
        continueNodeMap.remove(journeyId)?.let { node ->
            runCatching { node.close() }
                .onFailure { Log.w(TAG, "Failed to close ContinueNode for journeyId=$journeyId", it) }
        }
    }

    private fun removeJourney(journeyId: String) {
        clearNodeState(journeyId)
        nextMutexes.remove(journeyId)
        CoreRuntime.journeyRegistry.remove(journeyId)
    }

    private companion object {
        const val TAG = "JourneyHostApiImpl"
    }

    /** Cancels all in-flight coroutines. Called from [PingJourneyPlugin.onDetachedFromEngine]. */
    fun shutdown() {
        scope.cancel()
    }
}
