/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
package com.pingidentity.samples.pingonesample.notification


import com.pingidentity.pingonemfa.push.PushNotification
import java.util.concurrent.atomic.AtomicReference

/**
 * Single-slot in-process holder for the [PushNotification] currently being shown to the user
 * (as a tray banner, a full-screen [PushNotificationActivity], or both).
 *
 * PingOne only allows one outstanding push authentication request per device at a time — the
 * server does not queue concurrent requests — so this holder needs no more than one slot;
 * [put] overwrites any previous entry.
 *
 * ## Why it exists
 * Its sole purpose is coordinating the *in-process* teardown that a server-initiated cancel push
 * requires. When
 * [PushNotificationService.handleNotification][com.pingidentity.samples.pingonesample.service.PushNotificationService.handleNotification]
 * receives a cancel push it needs to answer two questions:
 *
 *  1. **Is a tray banner currently posted for this device?** The banner was posted with
 *     `notify(id.hashCode(), ...)`, so the service needs the id of what it last displayed to
 *     call `NotificationManagerCompat.cancel(id.hashCode())`. [remove] returns exactly that.
 *  2. **Is a [PushNotificationActivity] currently in the foreground?** If so, it must be
 *     `finish()`ed. The service publishes the id returned by [remove] onto [NotificationCancelBus];
 *     any open activity filters by matching id and closes itself.
 *
 * ## Lifecycle contract
 *  - Writers: [NotificationHelper.showPushNotification] calls [put] when it posts a background
 *    system notification, and `PushNotificationService.launchActivityFromForeground` calls
 *    [put] when it launches the full-screen activity directly for a foreground push. Either way
 *    the cancel path has something to look up.
 *  - Consumers of completion: [PushNotificationActivity], [NotificationActionReceiver], and the
 *    cancel path in `PushNotificationService.handleNotification` all call [remove] when they are
 *    done with the current notification, so the next push starts from a clean slot.
 *
 * ## Process death
 * If the OS kills the app between banner post and any subsequent event, this holder is
 * recreated empty on next process start. That is intentional and safe: the tap and approve/deny
 * paths do not depend on it (they read the Parcelable Intent extra), and the cancel path
 * correctly no-ops — there is no in-process banner or activity left to dismiss — while the
 * server-side authentication request eventually times out on its own.
 */
object PushNotificationStore {

    private val current = AtomicReference<PushNotification?>(null)

    /**
     * Records [notification] as the currently displayed push so that a subsequent cancel push
     * (or any completion path) has something to look up via [remove]. Overwrites any previous
     * entry — see the class KDoc for why one slot is sufficient.
     */
    fun put(notification: PushNotification) {
        current.set(notification)
    }

    /**
     * Returns the stored notification only if its [PushNotification.id] equals [id], otherwise
     * `null`. The id check is defensive: it prevents a caller from acting on a newer,
     * overwritten notification if it tries to look up an older one by id.
     *
     * Not used by the tap or approve/deny paths — those read the [PushNotification] directly
     * from their Parcelable Intent extra.
     */
    fun get(id: String): PushNotification? =
        current.get()?.takeIf { it.id == id }

    /**
     * Atomically clears the slot and returns the id of the notification that was in it, or
     * `null` if the slot was already empty.
     *
     * Called on completion (approve, deny, activity dismissed) and on cancel to tell the caller
     * *what* it just cleared — the returned id is used by
     * [PushNotificationService.handleNotification][com.pingidentity.samples.pingonesample.service.PushNotificationService.handleNotification]
     * to dismiss the tray banner (keyed by `id.hashCode()`) and to signal
     * [NotificationCancelBus] so any open [PushNotificationActivity] can `finish()` itself.
     */
    fun remove(): String? {
        return current.getAndSet(null)?.id
    }
}
