/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.service

import android.content.Intent
import androidx.annotation.RequiresPermission
import androidx.core.app.NotificationManagerCompat
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.ProcessLifecycleOwner
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.pingidentity.pingonemfa.commons.PingOneMFA
import com.pingidentity.pingonemfa.push.PushNotification
import com.pingidentity.samples.pingonesample.data.DiagnosticLogger
import com.pingidentity.samples.pingonesample.notification.NotificationCancelBus
import com.pingidentity.samples.pingonesample.notification.NotificationHelper
import com.pingidentity.samples.pingonesample.notification.PushNotificationActivity
import com.pingidentity.samples.pingonesample.notification.PushNotificationStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Service to handle incoming Firebase Cloud Messaging notifications.
 */
class PushNotificationService : FirebaseMessagingService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private val diagnosticLogger = DiagnosticLogger
    private lateinit var notificationHelper: NotificationHelper

    override fun onCreate() {
        super.onCreate()
        diagnosticLogger.d("PushNotificationService instance created")

        notificationHelper = NotificationHelper(this)
        notificationHelper.createNotificationChannels()
    }

    @RequiresPermission(android.Manifest.permission.POST_NOTIFICATIONS)
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        diagnosticLogger.d("Message received from: ${remoteMessage.from}")
        // Check if message contains a data payload.
        if (remoteMessage.data.isNotEmpty()) {
            diagnosticLogger.d("Message data payload: ${remoteMessage.data}")
            // Handle the data payload (e.g., display a notification)
            scope.launch {
                PingOneMFA.processRemoteNotification(remoteMessage)
                    .onSuccess { notification ->
                        diagnosticLogger.d("Successfully processed remote notification with PingOneMFA")
                        handleNotification(notification)
                    }
                    .onFailure { e ->
                        diagnosticLogger.e("Failed to process remote notification with PingOneMFA: ${e.message}")
                    }
            }
        } else  {
            diagnosticLogger.d("Message does not contain data payload")
        }
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        diagnosticLogger.d("Received new FCM token")

        // Handle the new token (e.g., send it to your server)
        scope.launch {
            PingOneMFA.setDeviceToken(token).onSuccess {
                diagnosticLogger.d("Successfully updated device token with PingOneMFA")
            }.onFailure { e ->
                diagnosticLogger.e("Failed to update device token with PingOneMFA: ${e.message}")
            }
        }
    }

    /**
     * Routes a decoded [PushNotification] to the correct destination.
     *
     *  - **Cancel push** — tear down whatever is currently showing (tray banner + open activity).
     *  - **Foreground** — the user is already in the app, so we launch [PushNotificationActivity]
     *    directly instead of posting a tray notification. This starts an activity from a Service,
     *    which is safe here specifically because the process is in the foreground: the Android 10+
     *    background-activity-start restriction does not apply, and any foreground push carries a
     *    short BAL grace regardless. We deliberately do NOT post a system notification in this
     *    case — the user is looking at the app, they don't need a heads-up.
     *  - **Background / screen off / locked** — post a system notification via
     *    [NotificationHelper.showPushNotification]. That notification has a full-screen intent
     *    attached, so the OS auto-launches [PushNotificationActivity] when the screen is off
     *    (with `showWhenLocked` / `turnScreenOn` on the manifest waking the display), and falls
     *    back to a heads-up on unlocked-but-elsewhere devices. This path never calls
     *    `startActivity` from the Service, so BAL restrictions are not a concern.
     */
    @RequiresPermission(android.Manifest.permission.POST_NOTIFICATIONS)
    fun handleNotification(notification: PushNotification) {
        diagnosticLogger.d("Handling notification: ${notification.id}")
        if (notification.isCancelAuthentication()) {
            diagnosticLogger.d("Notification is a cancellation, clearing store and dismissing UI")
            val cancelledId = PushNotificationStore.remove()
            if (cancelledId != null) {
                diagnosticLogger.d("Cancelled notification ID: $cancelledId")
                // Dismiss the system tray banner (keyed by hashCode, same as NotificationHelper)
                NotificationManagerCompat.from(applicationContext).cancel(cancelledId.hashCode())
                // Dismiss the foreground activity if it's open
                NotificationCancelBus.cancel(cancelledId)
            }
            return
        }
        if (isAppInForeground()) {
            diagnosticLogger.d("App is in foreground, launching PushNotificationActivity directly")
            scope.launch {
                launchActivityFromForeground(notification)
            }
        } else {
            diagnosticLogger.d("App is not in foreground, posting notification with full-screen intent")
            notificationHelper.showPushNotification(notification)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        diagnosticLogger.d("PushNotificationService instance destroyed")
    }

    /**
     * Uses [ProcessLifecycleOwner] to determine whether any activity of this process is currently
     * in the foreground. Replaces the deprecated `ActivityManager.getRunningAppProcesses` lookup
     * used in earlier revisions and is the recommended, non-deprecated API for process-wide
     * foreground state. `lifecycle.currentState` is thread-safe (backed by a volatile enum), so
     * this can be called from the service's IO scope without hopping to Main first.
     */
    private fun isAppInForeground(): Boolean =
        ProcessLifecycleOwner.get().lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)

    /**
     * Foreground path: mirror the notification into [PushNotificationStore] (so a subsequent
     * cancel push can locate an in-process activity to dismiss), then start
     * [PushNotificationActivity] carrying the full [PushNotification] as a Parcelable extra.
     * Runs on [Dispatchers.Main] because `startActivity` from a Service is a main-thread call.
     */
    private suspend fun launchActivityFromForeground(notification: PushNotification) {
        withContext(Dispatchers.Main) {
            try {
                PushNotificationStore.put(notification)
                val intent = Intent(applicationContext, PushNotificationActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra(PushNotificationActivity.EXTRA_PINGONE_NOTIFICATION, notification)
                }
                startActivity(intent)
            } catch (e: Exception) {
                diagnosticLogger.e(
                    "Failed to launch PushNotificationActivity from foreground — ${e.message}", e
                )
            }
        }
    }
}