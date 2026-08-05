/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.notification

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import com.pingidentity.pingonemfa.commons.PingOneMFA
import com.pingidentity.pingonemfa.push.PushNotification
import com.pingidentity.samples.pingonesample.data.DiagnosticLogger

/**
 * BroadcastReceiver to handle action button taps on PingOne MFA system notifications.
 *
 * Receives [ACTION_APPROVE] and [ACTION_DENY] intents fired from the notification banner,
 * then delegates to [PingOneMFA.approvePushNotificationFromBanner] /
 * [PingOneMFA.denyPushNotificationFromBanner], which route through
 * [com.pingidentity.pingonemfa.push.PushApprovalService] so the network call is allowed
 * even when the app is in the background.
 *
 * The [PushNotification] itself is carried as a Parcelable Intent extra. Android re-delivers
 * PendingIntent extras to a freshly launched receiver after process death, so approve/deny still
 * works after the OS kills the app while the tray banner is showing.
 *
 * ## Async handoff assumption
 * Both `approve/denyPushNotificationFromBanner` return `Unit` and are treated as **synchronous
 * handoff** calls: they enqueue the request onto the SDK's `PushApprovalService`, which owns the
 * actual HTTPS round-trip. Because the network I/O doesn't happen on this receiver's thread,
 * `goAsync()` is not required. If either method is ever changed to `suspend` — or to do network
 * I/O inline — this receiver must be updated to hold itself alive via `goAsync()` and complete
 * the [PendingResult] once the call returns; otherwise the process may be killed mid-request.
 *
 * Any exception thrown out of the handoff call is caught and logged rather than left to crash
 * the receiver, matching the review requirement that outcomes be surfaced through
 * [DiagnosticLogger] instead of being silently lost.
 */
class NotificationActionReceiver : BroadcastReceiver() {

    private val diagnosticLogger = DiagnosticLogger

    override fun onReceive(context: Context, intent: Intent) {
        val notification = intent.parcelablePushNotification() ?: run {
            diagnosticLogger.w(
                "NotificationActionReceiver: dropped ${intent.action ?: "<null action>"} — " +
                    "missing/invalid $EXTRA_PINGONE_NOTIFICATION extra",
                null
            )
            return
        }
        // Also clear our in-process reference (used by the cancel-path in the service) if it
        // matches. Post-process-death this will be a no-op, which is fine.
        PushNotificationStore.remove()
        // Dismiss the banner immediately so the user gets visual feedback
        NotificationManagerCompat.from(context).cancel(notification.id.hashCode())

        when (intent.action) {
            ACTION_APPROVE -> {
                diagnosticLogger.d("PingOne approve tapped for notification: ${notification.id}")
                try {
                    PingOneMFA.approvePushNotificationFromBanner(notification)
                    diagnosticLogger.i(
                        "PingOne approve handed off to PushApprovalService for ${notification.id}"
                    )
                } catch (e: Exception) {
                    diagnosticLogger.e(
                        "PingOne approve failed for ${notification.id} — ${e.message}", e
                    )
                }
            }
            ACTION_DENY -> {
                diagnosticLogger.d("PingOne deny tapped for notification: ${notification.id}")
                try {
                    PingOneMFA.denyPushNotificationFromBanner(notification)
                    diagnosticLogger.i(
                        "PingOne deny handed off to PushApprovalService for ${notification.id}"
                    )
                } catch (e: Exception) {
                    diagnosticLogger.e(
                        "PingOne deny failed for ${notification.id} — ${e.message}", e
                    )
                }
            }
            else -> {
                diagnosticLogger.w(
                    "NotificationActionReceiver: unknown action ${intent.action} for ${notification.id}",
                    null
                )
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun Intent.parcelablePushNotification(): PushNotification? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(EXTRA_PINGONE_NOTIFICATION, PushNotification::class.java)
        } else {
            getParcelableExtra<PushNotification>(EXTRA_PINGONE_NOTIFICATION)
        }

    companion object {
        const val ACTION_APPROVE = "com.pingidentity.pingsampleapp.PINGONE_ACTION_APPROVE"
        const val ACTION_DENY = "com.pingidentity.pingsampleapp.PINGONE_ACTION_DENY"
        /** Parcelable [PushNotification] extra carried by the approve/deny PendingIntents. */
        const val EXTRA_PINGONE_NOTIFICATION = "pingone_notification"
    }
}
