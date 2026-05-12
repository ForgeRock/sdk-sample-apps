/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.annotation.RequiresPermission
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.notification.NotificationActionReceiver.Companion.ACTION_APPROVE
import com.pingidentity.authenticatorapp.notification.NotificationActionReceiver.Companion.ACTION_DENY
import com.pingidentity.authenticatorapp.notification.NotificationActionReceiver.Companion.EXTRA_NOTIFICATION_ID
import com.pingidentity.mfa.push.PushNotification
import com.pingidentity.mfa.push.PushType

/**
 * Helper class for managing and displaying system notifications.
 */
class NotificationHelper(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "com.pingidentity.authenticatorapp.PUSH_NOTIFICATIONS"
        const val NOTIFICATION_GROUP = "com.pingidentity.authenticatorapp.PUSH_NOTIFICATION_GROUP"
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
     * Shows a notification for a push authentication request.
     *
     * @param notification The push notification to display
     * @param issuer The issuer of the authentication request (if available)
     * @param accountName The account name for the authentication request (if available)
     */
    @RequiresPermission(android.Manifest.permission.POST_NOTIFICATIONS)
    fun showPushAuthenticationNotification(
        notification: PushNotification,
        issuer: String?,
        accountName: String?
    ) {
        val notificationId = notification.id.hashCode()

        // Create an intent that opens the PushNotificationActivity directly
        val intent = Intent(context, PushNotificationActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            // Add notification ID
            putExtra(EXTRA_NOTIFICATION_ID, notification.id)
        }

        val pendingIntent = PendingIntent.getActivity(
            context, notificationId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build the notification title and content
        val title = issuer ?: context.getString(R.string.system_notification_title)

        val content = when {
            accountName != null -> "${context.getString(R.string.system_notification_content_for)} $accountName"
            else -> context.getString(R.string.system_notification_content)
        }

        // Build the notification
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(content)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL) // Authentication is similar to a call
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setGroup(NOTIFICATION_GROUP)

        // Add appropriate actions based on push type
        when (notification.pushType) {
            PushType.DEFAULT -> {
                // For DEFAULT type, add approve and deny buttons
                addDefaultTypeActions(builder, notification.id)
            }

            PushType.BIOMETRIC -> {
                // For BIOMETRIC type, add biometric authentication action
                addBiometricTypeAction(builder, notification.id)
            }

            PushType.CHALLENGE -> {
                // For CHALLENGE type, we don't add actions - user must open app
                builder.setContentText("$content ${context.getString(R.string.system_notification_challenge_required)}")
            }
        }

        // Show the notification
        with(NotificationManagerCompat.from(context)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                // Check for notification permission on Android 13+
                if (NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                    notify(notificationId, builder.build())
                }
            } else {
                notify(notificationId, builder.build())
            }
        }
    }

    /**
     * Adds approve and deny actions to a notification for DEFAULT push type.
     */
    private fun addDefaultTypeActions(builder: NotificationCompat.Builder, notificationId: String) {
        // Approve action
        val approveIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = ACTION_APPROVE
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        val approvePendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId.hashCode(),
            approveIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Deny action
        val denyIntent = Intent(context, NotificationActionReceiver::class.java).apply {
            action = ACTION_DENY
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        val denyPendingIntent = PendingIntent.getBroadcast(
            context,
            notificationId.hashCode() + 1, // Ensure a different request code
            denyIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Add the actions to the notification
        builder
            .addAction(
                R.drawable.ic_close, // Use appropriate icon
                context.getString(R.string.system_notification_deny),
                denyPendingIntent
            )
            .addAction(
                R.drawable.ic_check, // Use appropriate icon
                context.getString(R.string.system_notification_approve),
                approvePendingIntent
            )
    }

    /**
     * Adds biometric authentication action to a notification for BIOMETRIC push type.
     */
    private fun addBiometricTypeAction(
        builder: NotificationCompat.Builder,
        notificationId: String
    ) {
        // Instead of using BroadcastReceiver, directly create an activity intent for biometric authentication
        val biometricIntent = Intent(context, BiometricPromptActivity::class.java).apply {
            // Add flags to ensure the activity is shown when the device is locked or screen is off
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        
        // Create a PendingIntent for the activity
        val biometricPendingIntent = PendingIntent.getActivity(
            context,
            notificationId.hashCode(),
            biometricIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Add the action to the notification
        builder.addAction(
            R.drawable.ic_fingerprint, // Use appropriate icon
            context.getString(R.string.system_notification_authenticate),
            biometricPendingIntent
        )
    }
}
