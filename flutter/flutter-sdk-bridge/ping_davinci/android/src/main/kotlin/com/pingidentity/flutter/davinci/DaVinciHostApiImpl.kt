/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci

import android.util.Log
import com.pingidentity.davinci.collector.PollingCollector
import com.pingidentity.davinci.module.continueNode
import com.pingidentity.davinci.plugin.CollectorFactory
import com.pingidentity.davinci.plugin.collectors
import com.pingidentity.davinci.user
import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.mapper.JsonBridgeMapper
import com.pingidentity.flutter.davinci.collector.DaVinciCollectorValueApplier
import com.pingidentity.flutter.davinci.error.DaVinciErrorCodes
import com.pingidentity.flutter.davinci.error.DaVinciErrorMapper
import com.pingidentity.flutter.davinci.error.classifyError
import com.pingidentity.flutter.davinci.mapper.DaVinciNodeMapper
import com.pingidentity.flutter.davinci.mapper.DaVinciSessionMapper
import com.pingidentity.flutter.davinci.mapper.DaVinciValidationMapper
import com.pingidentity.flutter.davinci.mapper.collectorType
import com.pingidentity.flutter.davinci.polling.DaVinciPolling
import com.pingidentity.flutter.davinci.polling.DaVinciPollingEvents
import com.pingidentity.oidc.User
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.orchestrate.Session
import com.pingidentity.orchestrate.SuccessNode
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
 * Implements the generated [PingDaVinciHostApi]. `configureDaVinci` builds the native workflow
 * and registers it in `CoreRuntime.davinciRegistry`; `start`/`next` drive it and cache the current
 * [ContinueNode] per handle so `next()` and `validate()` can re-resolve collectors by
 * `{type, index}`. After a recoverable [ErrorNode] the cached node is the one it can be retried
 * from. A [SuccessNode]'s session is cached too, for [getSession]; tokens and userinfo come from
 * the native user, which owns and stores them. Polls run in [polling], which streams their
 * statuses to Dart; any call that moves a handle's flow on cancels that handle's polls first.
 */
class DaVinciHostApiImpl : PingDaVinciHostApi {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    /** The `pollingEvents` stream handler, registered by [PingDaVinciPlugin]. */
    internal val pollingEvents = DaVinciPollingEvents()

    private val polling = DaVinciPolling(scope, pollingEvents::send)

    /** Most recent [ContinueNode] per daVinciId: the current form, or an ErrorNode's retry node. */
    private val continueNodeMap = ConcurrentHashMap<String, ActiveNode>()

    /** The session of the [SuccessNode] each daVinciId reached, until it starts over or signs off. */
    private val successSessionMap = ConcurrentHashMap<String, Session>()

    /**
     * Serializes [next] and [validate] per daVinciId, so neither can apply values while the other
     * is reading or submitting the same collectors.
     */
    private val nextMutexes = ConcurrentHashMap<String, Mutex>()

    /** Cancels every in-flight call. Invoked from [PingDaVinciPlugin.onDetachedFromEngine]. */
    fun shutdown() {
        scope.cancel()
    }

    override fun configureDaVinci(
        config: DaVinciConfigMessage,
        callback: (Result<String>) -> Unit
    ) {
        callback(
            runCatching { DaVinciFactory.create(config) }
                .classifyError(DaVinciErrorCodes.CONFIGURE)
        )
    }

    override fun start(daVinciId: String, callback: (Result<NodeMessage>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val handle = resolveHandle(daVinciId)
                polling.cancelAll(daVinciId)
                val node = handle.daVinci.start()
                setNode(daVinciId, node)
                DaVinciNodeMapper.map(node)
            }
            callback(result.classifyError(DaVinciErrorCodes.START))
        }
    }

    override fun next(
        daVinciId: String,
        values: List<CollectorValueMessage?>,
        callback: (Result<NodeMessage>) -> Unit
    ) {
        scope.launch {
            val mutex = nextMutexes.getOrPut(daVinciId) { Mutex() }
            val result = mutex.withLock {
                runCatching {
                    val currentNode = activeContinueNode(daVinciId)
                    DaVinciCollectorValueApplier.apply(currentNode.collectors, values.filterNotNull())
                    // A finished poll has already set its collector's value; a running one is
                    // stopped so it can't write into the node being submitted.
                    polling.cancelAll(daVinciId)
                    // The SDK closes the submitted node itself (wiping Closeable collectors'
                    // values), so the bridge never calls close() here and never reads a collector
                    // of currentNode after this line.
                    val nextNode = currentNode.next()
                    setNode(daVinciId, nextNode)
                    DaVinciNodeMapper.map(nextNode)
                }
            }
            callback(result.classifyError(DaVinciErrorCodes.NEXT))
        }
    }

    /**
     * Applies [values] to the cached node's collectors, as `next()` would, then runs the SDK's
     * `validate()` on each, with no network call. `next()` never validates: the two are
     * independent, as in both native SDKs, and the values applied here stay applied.
     */
    override fun validate(
        daVinciId: String,
        values: List<CollectorValueMessage?>,
        callback: (Result<List<ValidationErrorMessage?>>) -> Unit
    ) {
        scope.launch {
            val mutex = nextMutexes.getOrPut(daVinciId) { Mutex() }
            val result = mutex.withLock {
                runCatching {
                    val currentNode = activeContinueNode(daVinciId)
                    DaVinciCollectorValueApplier.apply(currentNode.collectors, values.filterNotNull())
                    DaVinciValidationMapper.validate(currentNode.collectors)
                }
            }
            callback(result.classifyError(DaVinciErrorCodes.VALIDATE))
        }
    }

    /** A query: null until this handle reaches a [SuccessNode]. */
    override fun getSession(daVinciId: String, callback: (Result<SessionMessage?>) -> Unit) {
        callback(
            runCatching {
                resolveHandle(daVinciId)
                successSessionMap[daVinciId]?.let(DaVinciSessionMapper::session)
            }.classifyError(DaVinciErrorCodes.GET_SESSION)
        )
    }

    /**
     * Android exchanged the code when the flow reached its [SuccessNode], so this normally reads
     * the stored token, refreshing it if it has expired.
     */
    override fun getToken(daVinciId: String, callback: (Result<TokenMessage>) -> Unit) {
        scope.launch {
            val result = runCatching {
                when (val tokenResult = requireUser(daVinciId).token()) {
                    is PingResult.Success -> DaVinciSessionMapper.token(tokenResult.value)
                    is PingResult.Failure ->
                        throw DaVinciErrorMapper.fromOidcError(
                            DaVinciErrorCodes.GET_TOKEN,
                            tokenResult.value
                        )
                }
            }
            callback(result.classifyError(DaVinciErrorCodes.GET_TOKEN))
        }
    }

    override fun getUserInfo(
        daVinciId: String,
        cache: Boolean,
        callback: (Result<Map<String?, Any?>>) -> Unit
    ) {
        scope.launch {
            val result = runCatching {
                when (val userInfoResult = requireUser(daVinciId).userinfo(cache)) {
                    is PingResult.Success ->
                        @Suppress("UNCHECKED_CAST")
                        (JsonBridgeMapper.encodeJsonElement(userInfoResult.value)
                            as? Map<String?, Any?>) ?: emptyMap()
                    is PingResult.Failure ->
                        throw DaVinciErrorMapper.fromOidcError(
                            DaVinciErrorCodes.USERINFO,
                            userInfoResult.value
                        )
                }
            }
            callback(result.classifyError(DaVinciErrorCodes.USERINFO))
        }
    }

    /**
     * `Workflow.signOff()` ends the OIDC session (revoking the stored tokens) and deletes the
     * persisted session cookies, after which `DaVinci.user()` is null. Its failure is reported as
     * `false`, not thrown; only a missing handle throws.
     */
    override fun signOff(daVinciId: String, callback: (Result<Boolean>) -> Unit) {
        scope.launch {
            val result = runCatching {
                val handle = resolveHandle(daVinciId)
                polling.cancelAll(daVinciId)
                val signedOff =
                    handle.daVinci.signOff()
                        .onFailure { Log.w(TAG, "signOff failed for daVinciId=$daVinciId", it) }
                        .isSuccess
                clearNodeState(daVinciId)
                signedOff
            }
            callback(result.classifyError(DaVinciErrorCodes.SIGN_OFF))
        }
    }

    override fun dispose(daVinciId: String, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            val result = runCatching {
                polling.cancelAll(daVinciId)
                clearNodeState(daVinciId)
                nextMutexes.remove(daVinciId)
                CoreRuntime.davinciRegistry.remove(daVinciId)
                Unit
            }
            callback(result.classifyError(DaVinciErrorCodes.DISPOSE))
        }
    }

    /**
     * Resolves the `POLLING` collector by `{collectorType, index}` on the cached node, under the
     * same lock as [next], so a poll can't start on a node that is being submitted.
     */
    override fun startPolling(
        daVinciId: String,
        pollId: String,
        collectorType: String,
        index: Long,
        callback: (Result<Unit>) -> Unit
    ) {
        scope.launch {
            val mutex = nextMutexes.getOrPut(daVinciId) { Mutex() }
            val result = mutex.withLock {
                runCatching {
                    resolveHandle(daVinciId)
                    val collectors = activeContinueNode(daVinciId).collectors
                    val collector =
                        collectors.getOrNull(index.toInt())
                            ?: throw IllegalArgumentException(
                                "No collector at index=$index (the node has ${collectors.size})"
                            )
                    val actual = collectorType(collector)
                    require(actual == collectorType) {
                        "Collector at index=$index is $actual, not $collectorType"
                    }
                    require(collector is PollingCollector) {
                        "$collectorType at index=$index is not a polling collector"
                    }
                    polling.start(daVinciId, pollId, collector)
                }
            }
            callback(result.classifyError(DaVinciErrorCodes.START_POLLING))
        }
    }

    override fun cancelPolling(pollId: String, callback: (Result<Unit>) -> Unit) {
        scope.launch {
            val result = runCatching { polling.cancel(pollId) }
            callback(result.classifyError(DaVinciErrorCodes.CANCEL_POLLING))
        }
    }

    override fun activePollCount(callback: (Result<Long>) -> Unit) {
        callback(
            runCatching { polling.activeCount.toLong() }
                .classifyError(DaVinciErrorCodes.ACTIVE_POLL_COUNT)
        )
    }

    override fun registeredCollectorTypes(
        daVinciId: String,
        callback: (Result<List<String>>) -> Unit
    ) {
        callback(
            runCatching {
                resolveHandle(daVinciId)
                CollectorFactory.collectors().keys.sorted()
            }.classifyError(DaVinciErrorCodes.REGISTERED_COLLECTOR_TYPES)
        )
    }

    private fun resolveHandle(daVinciId: String): DaVinciHandle =
        CoreRuntime.davinciRegistry.resolve(daVinciId) as? DaVinciHandle
            ?: throw IllegalStateException("DaVinci instance not found for id=$daVinciId")

    private fun activeContinueNode(daVinciId: String): ContinueNode =
        continueNodeMap[daVinciId]?.node
            ?: throw IllegalStateException("No active ContinueNode found for daVinciId=$daVinciId")

    /**
     * The signed-in user, or a typed `state` error. `DaVinci.user()` is
     * `oidcUser().takeIf { hasCookies() }`: it is null whenever the persisted session cookie is
     * gone (never signed in, or signed off), even if tokens are still stored. iOS returns its
     * cached user without checking cookies; the bridge drops that cache on sign-off, so the two
     * agree on every path the bridge drives.
     */
    private suspend fun requireUser(daVinciId: String): User =
        resolveHandle(daVinciId).daVinci.user()
            ?: throw IllegalStateException(
                "No signed-in DaVinci user for daVinciId=$daVinciId: complete the flow first"
            )

    /**
     * A recoverable [ErrorNode] keeps its retry node (`continueNode()`, normally the node just
     * submitted) as the active one, so the app can correct a value and submit again. Nothing is
     * closed here: the SDK closes every node it submits.
     */
    private fun setNode(daVinciId: String, node: Node) {
        val active =
            when (node) {
                is ContinueNode -> ActiveNode(node, submitted = false)
                is ErrorNode -> node.continueNode()?.let { ActiveNode(it, submitted = true) }
                else -> null
            }
        if (active != null) {
            continueNodeMap[daVinciId] = active
        } else {
            continueNodeMap.remove(daVinciId)
        }
        if (node is SuccessNode) {
            successSessionMap[daVinciId] = node.session
        } else {
            successSessionMap.remove(daVinciId)
        }
    }

    /**
     * Drops the cached nodes. Only a never-submitted node is closed (so its Closeable collectors
     * drop their values): the SDK already closed an ErrorNode's retry node when it was submitted.
     */
    private fun clearNodeState(daVinciId: String) {
        successSessionMap.remove(daVinciId)
        val active = continueNodeMap.remove(daVinciId) ?: return
        if (active.submitted) return
        runCatching { active.node.close() }
            .onFailure { Log.w(TAG, "Failed to close ContinueNode for daVinciId=$daVinciId", it) }
    }

    /** A cached [ContinueNode], and whether the SDK has already submitted (and closed) it. */
    private class ActiveNode(val node: ContinueNode, val submitted: Boolean)

    private companion object {
        const val TAG = "PingDaVinci"
    }
}
