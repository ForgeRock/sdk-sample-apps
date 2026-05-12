package com.pingidentity.authenticatorapp.service

import android.app.ActivityManager
import android.content.Intent
import androidx.annotation.RequiresPermission
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.pingidentity.authenticatorapp.AuthenticatorApp
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.notification.NotificationActionReceiver
import com.pingidentity.authenticatorapp.notification.NotificationHelper
import com.pingidentity.authenticatorapp.notification.PushNotificationActivity
import com.pingidentity.mfa.push.PushClient
import com.pingidentity.mfa.push.PushNotification
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * Service to handle incoming Firebase Cloud Messaging notifications.
 */
class PushNotificationService : FirebaseMessagingService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var pushClient: PushClient? = null

    private val diagnosticLogger = DiagnosticLogger

    private lateinit var notificationHelper: NotificationHelper


    override fun onCreate() {
        super.onCreate()
        diagnosticLogger.d("PushNotificationService instance created")

        notificationHelper = NotificationHelper(this)
        notificationHelper.createNotificationChannels()

        scope.launch {
            pushClient = AuthenticatorApp.Companion.getPushClient(application)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        diagnosticLogger.d("PushNotificationService instance destroyed")
    }

    /**
     * Checks if the application is currently in foreground.
     *
     * @return True if the app is in foreground, false otherwise
     */
    private fun isAppInForeground(): Boolean {
        val activityManager = getSystemService(ACTIVITY_SERVICE) as ActivityManager
        val appProcesses = activityManager.runningAppProcesses ?: return false
        val packageName = packageName

        for (appProcess in appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                appProcess.processName == packageName) {
                return true
            }
        }
        return false
    }

    /**
     * Called when a new token is generated.
     */
    override fun onNewToken(token: String) {
        diagnosticLogger.d("New FCM token: ${token.take(8)}...${token.takeLast(4)}")
        scope.launch {
            // Update the device token in the PushClient
            pushClient?.setDeviceToken(token)
        }
    }

    /**
     * Called when a message is received.
     */
    @RequiresPermission(android.Manifest.permission.POST_NOTIFICATIONS)
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        diagnosticLogger.d("Message received from: ${remoteMessage.from}")

        // Handle the message data payload
        if (remoteMessage.data.isNotEmpty()) {
            diagnosticLogger.d("Message data payload: ${remoteMessage.data}")

            scope.launch {
                try {
                    // Process the notification using PushClient directly
                    val result = pushClient?.processNotification(remoteMessage.data as Map<String, Any>)?.getOrNull()
                    result?.let { notification ->
                        handleNotification(notification)
                    }
                } catch (e: Exception) {
                    diagnosticLogger.e("Error processing notification: ${e.message}")
                }
            }
        }
    }

    /**
     * Displays a system notification for the push authentication request.
     */
    @RequiresPermission(android.Manifest.permission.POST_NOTIFICATIONS)
    private fun displaySystemNotification(notification: PushNotification) {
        // Find the associated credential to get issuer and account name
        scope.launch(Dispatchers.Main) {
            try {
                val credentials = pushClient?.getCredentials()?.getOrElse { emptyList() } ?: emptyList()
                val credential = credentials.find { it.id == notification.credentialId }

                // Display the notification with credential info if available
                notificationHelper.showPushAuthenticationNotification(
                    notification = notification,
                    issuer = credential?.issuer,
                    accountName = credential?.accountName
                )
            } catch (e: Exception) {
                diagnosticLogger.e("Error displaying notification: ${e.message}")
                // Fall back to showing a notification without credential details
                notificationHelper.showPushAuthenticationNotification(
                    notification = notification,
                    issuer = null,
                    accountName = null
                )
            }
        }
    }

    /**
     * Shows a full-screen notification when the app is in the foreground.
     * This launches the PushNotificationActivity directly.
     *
     * @param notification The push notification to display
     */
    private fun showFullScreenNotification(notification: PushNotification) {
        scope.launch(Dispatchers.Main) {
            try {
                diagnosticLogger.d("Showing full screen notification: ${notification.id}")

                // Launch the PushNotificationActivity with the notification ID
                val intent = Intent(applicationContext, PushNotificationActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra(NotificationActionReceiver.Companion.EXTRA_NOTIFICATION_ID, notification.id)
                }

                startActivity(intent)
            } catch (e: Exception) {
                diagnosticLogger.e("Error showing full-screen notification: ${e.message}")
            }
        }
    }

    /**
     * Handle a notification that's already been processed.
     * This displays system notifications and launches full-screen notifications when appropriate.
     */
    @RequiresPermission(android.Manifest.permission.POST_NOTIFICATIONS)
    fun handleNotification(notification: PushNotification) {
        diagnosticLogger.d("Handling notification: ${notification.id}")
        
        // If app is in foreground, also display the notification full screen immediately
        if (isAppInForeground()) {
            diagnosticLogger.d("App is in foreground, launching notification activity")
            showFullScreenNotification(notification)
        } else {
            diagnosticLogger.d("App is in background, displaying system notification")
            displaySystemNotification(notification)
        }
    }
}