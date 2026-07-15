/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.journey.callback.JourneyCallbackValueApplier
import com.pingidentity.flutter.journey.error.JourneyErrorCodes
import com.pingidentity.flutter.journey.error.JourneyErrorMapper
import com.pingidentity.flutter.journey.error.classifyError
import com.pingidentity.flutter.journey.mapper.JourneyNodeMapper
import com.pingidentity.flutter.journey.mapper.JsonBridgeMapper
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

/**
 * Implements the generated [PingJourneyHostApi]: `configureJourney`/`start` build the native
 * `Journey` and cache the current node per `journeyId`; `next()` applies submitted callback
 * values onto the cached [ContinueNode] and advances the flow.
 */
class JourneyHostApiImpl : PingJourneyHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** Most recent [Node] per journeyId. */
    private val nodeMap = ConcurrentHashMap<String, Node>()

    /** Most recent [ContinueNode] per journeyId, for future callback re-resolution. */
    private val continueNodeMap = ConcurrentHashMap<String, ContinueNode>()

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
            val result = runCatching {
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
                                    is PingResult.Failure -> null
                                }
                                SessionMessage(
                                    accessToken = token.accessToken,
                                    refreshToken = token.refreshToken,
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

    override fun signOff(journeyId: String, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val handle = resolveHandle(journeyId)
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
        nodeMap[journeyId] = node
        if (node is ContinueNode) {
            continueNodeMap[journeyId] = node
        } else {
            continueNodeMap.remove(journeyId)
        }
    }

    private fun clearNodeState(journeyId: String) {
        nodeMap.remove(journeyId)
        continueNodeMap.remove(journeyId)
    }

    private fun removeJourney(journeyId: String) {
        continueNodeMap.remove(journeyId)?.let { node ->
            runCatching { node.close() }
                .onFailure { Log.w(TAG, "Failed to close ContinueNode for journeyId=$journeyId", it) }
        }
        nodeMap.remove(journeyId)
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
