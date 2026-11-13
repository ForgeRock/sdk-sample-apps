/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.polling

import com.pingidentity.davinci.collector.PollingCollector
import com.pingidentity.davinci.collector.PollingStatus
import com.pingidentity.flutter.davinci.PollingEventMessage
import com.pingidentity.flutter.davinci.PollingStatusKind
import java.util.Collections
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

/**
 * The polling runner on real simple-mode collectors (challenge mode needs a `DaVinci`, which a
 * JVM test can't build; the integration tests cover it), and the status mapping for every case.
 */
class DaVinciPollingTest {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val events = Collections.synchronizedList(mutableListOf<PollingEventMessage>())
    private val polling = DaVinciPolling(scope, events::add, dispatch = { it() })

    @AfterTest
    fun tearDown() {
        scope.cancel()
    }

    private fun simple(interval: Long, retries: Int) =
        PollingCollector().init(
            Json.parseToJsonElement(
                """{"type":"POLLING","key":"polling-field","pollInterval":"$interval","pollRetries":"$retries"}"""
            ).jsonObject
        )

    private suspend fun awaitIdle() = withTimeout(5_000) {
        while (polling.activeCount > 0) delay(5)
    }

    @Test
    fun `a simple-polling cycle is one terminal event, and sets the collector's value`() = runBlocking {
        val collector = simple(interval = 10, retries = 3)

        polling.start("handle", "poll-1", collector)
        awaitIdle()

        assertEquals(
            listOf(PollingEventMessage("poll-1", PollingStatusKind.COMPLETE, status = "continue")),
            events.toList(),
        )
        assertEquals("continue", collector.value)
        assertEquals(2, collector.retriesAllowed)
    }

    @Test
    fun `the last simple-polling retry times out`() = runBlocking {
        val collector = simple(interval = 10, retries = 1)

        polling.start("handle", "poll-1", collector)
        awaitIdle()

        assertEquals(listOf(PollingStatusKind.TIMED_OUT), events.map { it.kind })
        assertEquals("timedOut", collector.value)
    }

    @Test
    fun `a cancelled poll stops, reports nothing more, and is released`() = runBlocking {
        val collector = simple(interval = 60_000, retries = 3)

        polling.start("handle", "poll-1", collector)
        assertEquals(1, polling.activeCount)
        polling.cancel("poll-1")

        assertEquals(0, polling.activeCount)
        delay(50)
        assertEquals(emptyList<PollingEventMessage>(), events.toList())
        assertEquals("", collector.value, "the cancelled delay never set a value")
        polling.cancel("poll-1") // Unknown ids are ignored.
    }

    @Test
    fun `cancelAll stops only that handle's polls`() = runBlocking {
        polling.start("a", "poll-a", simple(interval = 60_000, retries = 3))
        polling.start("b", "poll-b", simple(interval = 60_000, retries = 3))

        polling.cancelAll("a")

        assertEquals(1, polling.activeCount)
        polling.cancelAll("b")
        assertEquals(0, polling.activeCount)
    }

    @Test
    fun `a poll id can't run twice at once`() {
        polling.start("handle", "poll-1", simple(interval = 60_000, retries = 3))

        assertFailsWith<IllegalArgumentException> {
            polling.start("handle", "poll-1", simple(interval = 60_000, retries = 3))
        }
    }

    @Test
    fun `maps every status`() {
        assertEquals(
            PollingEventMessage("p", PollingStatusKind.CONTINUING, retryCount = 2, maxRetries = 3),
            DaVinciPollingMapper.event("p", PollingStatus.Continue(2, 3)),
        )
        assertEquals(
            PollingEventMessage("p", PollingStatusKind.TIMED_OUT),
            DaVinciPollingMapper.event("p", PollingStatus.TimedOut),
        )
        assertEquals(
            PollingEventMessage("p", PollingStatusKind.EXPIRED),
            DaVinciPollingMapper.event("p", PollingStatus.Expired),
        )
        assertEquals(
            PollingEventMessage("p", PollingStatusKind.ERROR, errorMessage = "Server error: 500"),
            DaVinciPollingMapper.event("p", PollingStatus.Error(IllegalStateException("Server error: 500"))),
        )
        assertEquals(
            PollingEventMessage("p", PollingStatusKind.COMPLETE, status = "approved"),
            DaVinciPollingMapper.event("p", PollingStatus.Complete("approved")),
        )
    }
}
