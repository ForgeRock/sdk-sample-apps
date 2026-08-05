/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.notification

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.annotation.RequiresPermission
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.pingidentity.pingonemfa.push.PushNotification
import com.pingidentity.pingonemfa.push.PushType
import com.pingidentity.samples.pingonesample.R

/**
 * Helper class for managing and displaying system notifications.
 */
class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "com.pingidentity.pingonesample.PUSH_NOTIFICATIONS"
        const val NOTIFICATION_GROUP = "com.pingidentity.pingonesample.PUSH_NOTIFICATION_GROUP"
    }
    /**
     * Creates the notification channels needed by the app.
     * This should be called at app startup.
     */
    fun createNotificationChannels() {
        val name = context.getString(R.string.notification_channel_name)
        val descriptionText = context.getString(R.string.notification_channel_description)
        val importance = NotificationManager.IMPORTANCE_HIGH // High importance for auth requests

        val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
            description = descriptionText
            enableVibration(true)
            enableLights(true)
        }

        // Register the channel with the system
        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.createNotificationChannel(channel)
    }

    /**
     * Posts a system notification for [notification].
     *
     * Behaviour:
     *  - Uses [PushNotification.title] and [PushNotification.message] as the banner text,
     *    falling back to generic string resources when either is null.
     *  - Adds Allow / Deny action buttons only for [PushType.DEFAULT].
     *  - The same PendingIntent that opens [PushNotificationActivity] on tap is also attached
     *    via [NotificationCompat.Builder.setFullScreenIntent], so the OS launches the activity
     *    directly when the screen is off or the device is locked — no `startActivity` call from
     *    the Service is needed, which avoids Android 10+ background-activity-start restrictions.
     *    When the app is in the foreground the platform ignores the full-screen intent and shows
     *    the notification as a heads-up (the desired behaviour).
     *  - [NotificationCompat.CATEGORY_CALL] + [NotificationCompat.PRIORITY_HIGH] + lock-screen
     *    [NotificationCompat.VISIBILITY_PUBLIC] give the OS the strongest possible signal that
     *    this is a real-time interruption.
     *
     * Note: on Android 14+ the `USE_FULL_SCREEN_INTENT` permission is auto-granted only to
     * phone/alarm apps; other apps (like this sample) fall back to a heads-up notification
     * unless the user grants the app-level toggle in Settings. That fallback is acceptable —
     * the notification body and action buttons remain functional.
     */
    @RequiresPermission(Manifest.permission.POST_NOTIFICATIONS)
    fun showPushNotification(notification: PushNotification) {
        val notificationId = notification.id.hashCode()

        val title = notification.title ?: context.getString(R.string.system_notification_title)
        val message = notification.message ?: context.getString(R.string.system_notification_content)

        val openAppPendingIntent = buildOpenAppPendingIntent(notification, notificationId)

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(openAppPendingIntent)
            // highPriority = true asks the OS to fire the full-screen intent even from a locked
            // screen, matching CATEGORY_CALL semantics. The OS decides whether to actually launch
            // the activity or fall back to a heads-up based on the app's foreground state and
            // the USE_FULL_SCREEN_INTENT app-level permission (Android 14+).
            .setFullScreenIntent(openAppPendingIntent, /* highPriority = */ true)

        if (notification.getPushType() == PushType.DEFAULT) {
            builder
                .addAction(buildDenyAction(notification, notificationId))
                .addAction(buildApproveAction(notification, notificationId))
        }

        with(NotificationManagerCompat.from(context)) {
            if (areNotificationsEnabled()) {
                // Record in-process only once we know the banner will actually be posted.
                PushNotificationStore.put(notification)
                notify(notificationId, builder.build())
            }
        }
    }

    private fun buildOpenAppPendingIntent(
        notification: PushNotification,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, PushNotificationActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra(PushNotificationActivity.EXTRA_PINGONE_NOTIFICATION, notification)
        }
        return PendingIntent.getActivity(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun buildDenyAction(
        notification: PushNotification,
        requestCode: Int,
    ): NotificationCompat.Action {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_DENY
            putExtra(NotificationActionReceiver.EXTRA_PINGONE_NOTIFICATION, notification)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Action(
            R.drawable.ic_close,
            context.getString(R.string.system_notification_deny),
            pendingIntent
        )
    }

    private fun buildApproveAction(
        notification: PushNotification,
        requestCode: Int,
    ): NotificationCompat.Action {
        val intent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_APPROVE
            putExtra(NotificationActionReceiver.EXTRA_PINGONE_NOTIFICATION, notification)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, requestCode + 1, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Action(
            R.drawable.ic_check,
            context.getString(R.string.system_notification_approve),
            pendingIntent
        )
    }
}