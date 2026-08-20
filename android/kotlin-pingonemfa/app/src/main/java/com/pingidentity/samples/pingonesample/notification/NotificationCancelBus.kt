/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.notification

import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

/**
 * Process-wide event bus for push notification cancellation signals.
 *
 * When the server cancels an outstanding authentication request (e.g. because the user
 * approved on another device), [com.pingidentity.samples.pingonesample.service.PushNotificationService] calls [cancel] with the affected
 * notification ID. [PushNotificationActivity] collects [cancellations] and calls `finish()`
 * if the ID matches the notification it is currently showing.
 *
 * This replaces the deprecated LocalBroadcastManager.
 *
 * ## Replay contract
 * `replay = 1` ensures a cancel signal emitted before [PushNotificationActivity] has started
 * collecting is not silently dropped. Without replay, the `lifecycleScope.launch { collect { … } }`
 * coroutine in `onCreate` may not reach its `collect` suspension point before `tryEmit` fires —
 * the value lands in `extraBufferCapacity`, nothing drains it, and it disappears. With `replay = 1`
 * the most recently emitted ID is cached and immediately delivered to any late subscriber.
 *
 * Stale replays from a *previous* push cycle are harmless: [PushNotificationActivity] always
 * filters by `cancelledId == notificationId`, so a mismatched replay is a no-op.
 */
object NotificationCancelBus {

    private val _cancellations = MutableSharedFlow<String>(replay = 1, extraBufferCapacity = 1)

    /** Emits the ID of a notification that has been canceled by the server. */
    val cancellations: SharedFlow<String> = _cancellations.asSharedFlow()

    /**
     * Emits a cancellation signal for the given notification [id].
     * Safe to call from any thread or coroutine context.
     */
    fun cancel(id: String) {
        _cancellations.tryEmit(id)
    }
}
