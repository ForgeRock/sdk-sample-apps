/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
package com.pingidentity.rnsampleapp

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.pingidentity.rnpush.RNPingPushBridge

/**
 * FCM messaging service for the sample app.
 *
 * Forwards token and message events to the Ping Push SDK via [RNPingPushBridge],
 * and posts a system tray notification when the app is backgrounded or killed.
 *
 * Declare in AndroidManifest.xml:
 * ```xml
 * <service android:name=".PushMessagingService" android:exported="false">
 *   <intent-filter>
 *     <action android:name="com.google.firebase.MESSAGING_EVENT" />
 *   </intent-filter>
 * </service>
 * ```
 */
class PushMessagingService : FirebaseMessagingService() {

    override fun onCreate() {
        super.onCreate()
        ensureNotificationChannel(this)
    }

    override fun onNewToken(token: String) {
        RNPingPushBridge.forwardToken(token)
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        if (remoteMessage.data.isEmpty()) return
        RNPingPushBridge.forwardNotification(remoteMessage.data)
        if (!isAppInForeground()) {
            postSystemNotification(remoteMessage.data)
        }
    }

    private fun isAppInForeground(): Boolean {
        val am = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        return am.runningAppProcesses?.any {
            it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                it.processName == packageName
        } ?: false
    }

    private fun postSystemNotification(data: Map<String, String>) {
        val payload = org.json.JSONObject(data).toString()
        val notificationId = payload.hashCode()

        val launcherIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(RNPingPushBridge.EXTRA_PUSH_COLD_START, true)
            putExtra(RNPingPushBridge.EXTRA_PUSH_PAYLOAD, payload)
        } ?: return

        val pendingIntent = PendingIntent.getActivity(
            this, notificationId, launcherIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val (title, body) = RNPingPushBridge.extractNotificationText(
            data,
            getString(R.string.ping_push_notification_title),
            getString(R.string.ping_push_notification_body),
        )

        val iconRes = resources.getIdentifier("ping_push_notification_icon", "drawable", packageName)
            .takeIf { it != 0 } ?: android.R.drawable.ic_dialog_info

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setColor(getColor(R.color.ping_push_notification_color))
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setGroup(NOTIFICATION_GROUP)
            .build()

        if (NotificationManagerCompat.from(this).areNotificationsEnabled()) {
            NotificationManagerCompat.from(this).notify(notificationId, notification)
        }
    }

    companion object {
        private const val CHANNEL_ID = "com.pingidentity.rnpush.channel"
        private const val NOTIFICATION_GROUP = "com.pingidentity.rnpush.group"

        fun ensureNotificationChannel(context: Context) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.ping_push_channel_name),
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = context.getString(R.string.ping_push_channel_description)
                enableVibration(true)
                enableLights(true)
            }
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }
}
