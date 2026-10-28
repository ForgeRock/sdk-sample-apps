/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.polling

import android.os.Handler
import android.os.Looper
import com.pingidentity.davinci.collector.PollingCollector
import com.pingidentity.davinci.collector.PollingStatus
import com.pingidentity.flutter.davinci.PigeonEventSink
import com.pingidentity.flutter.davinci.PollingEventMessage
import com.pingidentity.flutter.davinci.PollingEventsStreamHandler
import com.pingidentity.flutter.davinci.PollingStatusKind
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.launch

/**
 * Runs [PollingCollector.pollStatus] for Dart and hands each status to [emit], tagged with the
 * poll id Dart chose; in the plugin [emit] is [DaVinciPollingEvents.send], the one
 * `pollingEvents` event channel.
 *
 * Each poll is a job in [scope]. Cancelling it cancels the collecting coroutine, and the SDK's
 * `flow {}` is cold, so its `delay` and in-flight HTTP request stop with it: no request follows a
 * cancel. Android emits each status in the normalized order as it is (see
 * [DaVinciPollingMapper]); only iOS needs reordering.
 *
 * [dispatch] runs each delivery on the thread [emit] needs: Flutter's event sinks need the main
 * thread. Tests run it inline.
 */
internal class DaVinciPolling(
    private val scope: CoroutineScope,
    private val emit: (PollingEventMessage) -> Unit,
    private val dispatch: (() -> Unit) -> Unit = mainThread(),
) {
    private val polls = ConcurrentHashMap<String, Poll>()

    /** The polls still running. */
    val activeCount: Int
        get() = polls.size

    /** Starts polling [collector] for [daVinciId], reporting as [pollId]. */
    fun start(daVinciId: String, pollId: String, collector: PollingCollector) {
        val job = scope.launch(start = CoroutineStart.LAZY) { run(pollId, collector) }
        val poll = Poll(daVinciId, job)
        require(polls.putIfAbsent(pollId, poll) == null) { "Poll id $pollId is already running" }
        job.invokeOnCompletion { polls.remove(pollId, poll) }
        job.start()
    }

    /** Cancels [pollId] and waits for its job to finish. Unknown ids are ignored. */
    suspend fun cancel(pollId: String) {
        polls.remove(pollId)?.stop()
    }

    /** Cancels every poll of [daVinciId]: on start-over, flow advance, sign-off and dispose. */
    suspend fun cancelAll(daVinciId: String) {
        polls.entries.filter { it.value.daVinciId == daVinciId }.forEach { (pollId, poll) ->
            if (polls.remove(pollId, poll)) poll.stop()
        }
    }

    private suspend fun run(pollId: String, collector: PollingCollector) {
        var terminal = false
        collector.pollStatus().collect { status ->
            terminal = status !is PollingStatus.Continue
            send(pollId, DaVinciPollingMapper.event(pollId, status))
        }
        if (!terminal) {
            send(pollId, DaVinciPollingMapper.error(pollId, "Polling ended without a final status"))
        }
    }

    /** Drops the event if [pollId] was cancelled before the main thread delivers it. */
    private fun send(pollId: String, event: PollingEventMessage) {
        val poll = polls[pollId] ?: return
        dispatch {
            if (poll.active) emit(event)
        }
    }

    private class Poll(val daVinciId: String, val job: Job) {
        @Volatile var active = true

        suspend fun stop() {
            active = false
            job.cancelAndJoin()
        }
    }

    private companion object {
        fun mainThread(): (() -> Unit) -> Unit {
            val handler = Handler(Looper.getMainLooper())
            return { block -> handler.post(block) }
        }
    }
}

/**
 * The `pollingEvents` event channel's handler: holds Dart's sink while Dart listens. Events sent
 * while nobody listens are dropped; Dart listens before it starts a poll.
 */
internal class DaVinciPollingEvents : PollingEventsStreamHandler() {
    @Volatile private var sink: PigeonEventSink<PollingEventMessage>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<PollingEventMessage>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    /** Call on the main thread. */
    fun send(event: PollingEventMessage) {
        sink?.success(event)
    }
}

/** Maps a native [PollingStatus] to its wire [PollingEventMessage]. */
internal object DaVinciPollingMapper {
    fun event(pollId: String, status: PollingStatus): PollingEventMessage =
        when (status) {
            is PollingStatus.Continue ->
                PollingEventMessage(
                    pollId = pollId,
                    kind = PollingStatusKind.CONTINUING,
                    retryCount = status.retryCount.toLong(),
                    maxRetries = status.maxRetries.toLong(),
                )
            PollingStatus.TimedOut -> PollingEventMessage(pollId = pollId, kind = PollingStatusKind.TIMED_OUT)
            PollingStatus.Expired -> PollingEventMessage(pollId = pollId, kind = PollingStatusKind.EXPIRED)
            is PollingStatus.Error ->
                error(pollId, status.exception.message ?: status.exception::class.simpleName ?: "Polling failed")
            is PollingStatus.Complete ->
                PollingEventMessage(pollId = pollId, kind = PollingStatusKind.COMPLETE, status = status.status)
        }

    fun error(pollId: String, message: String): PollingEventMessage =
        PollingEventMessage(pollId = pollId, kind = PollingStatusKind.ERROR, errorMessage = message)
}
