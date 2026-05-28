/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.notification

import android.app.Application
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationManagerCompat
import com.pingidentity.authenticatorapp.AuthenticatorApp
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.mfa.commons.exception.CredentialNotFoundException
import com.pingidentity.mfa.push.exception.NotificationExpiredException
import com.pingidentity.mfa.push.exception.NotificationNotFoundException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

/**
 * BroadcastReceiver to handle notification actions.
 */
class NotificationActionReceiver : BroadcastReceiver() {
    
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private val diagnosticLogger = DiagnosticLogger

    companion object {
        const val ACTION_APPROVE = "com.pingidentity.authenticatorapp.ACTION_APPROVE"
        const val ACTION_DENY = "com.pingidentity.authenticatorapp.ACTION_DENY"
        const val ACTION_BIOMETRIC = "com.pingidentity.authenticatorapp.ACTION_BIOMETRIC"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        val notificationId = intent.getStringExtra(EXTRA_NOTIFICATION_ID) ?: return
        val notificationHashCode = notificationId.hashCode()
        
        // Cancel the notification immediately to provide feedback that the action was received
        NotificationManagerCompat.from(context).cancel(notificationHashCode)
        
        when (intent.action) {
            ACTION_APPROVE -> {
                diagnosticLogger.d("Approve action received for notification: $notificationId")
                approveNotification(context, notificationId)
            }
            ACTION_DENY -> {
                diagnosticLogger.d("Deny action received for notification: $notificationId")
                denyNotification(context, notificationId)
            }
            ACTION_BIOMETRIC -> {
                diagnosticLogger.d("Biometric action received for notification: $notificationId")
                handleBiometricAuthentication(context, notificationId)
            }
        }
    }
    
    /**
     * Approves the notification with the given ID.
     */
    private fun approveNotification(context: Context, notificationId: String) {
        scope.launch {
            try {
                val applicationContext = context.applicationContext
                val pushClient = AuthenticatorApp.getPushClient(applicationContext as Application)
                pushClient.approveNotification(notificationId)
            } catch (e: NotificationExpiredException) {
                diagnosticLogger.w("Notification expired: ${e.message}", e)
                // Notification has expired - user may see it was removed or marked expired in the app
            } catch (e: NotificationNotFoundException) {
                diagnosticLogger.w("Notification not found: ${e.message}", e)
                // Notification was not found - may have been deleted
            } catch (e: CredentialNotFoundException) {
                diagnosticLogger.w("Credential not found: ${e.message}", e)
                // Credential was not found - user needs to re-register
            } catch (e: Exception) {
                diagnosticLogger.e("Error approving notification: ${e.message}", e)
            }
        }
    }
    
    /**
     * Denies the notification with the given ID.
     */
    private fun denyNotification(context: Context, notificationId: String) {
        scope.launch {
            try {
                val applicationContext = context.applicationContext
                val pushClient = AuthenticatorApp.getPushClient(applicationContext as Application)
                pushClient.denyNotification(notificationId)
            } catch (e: NotificationExpiredException) {
                diagnosticLogger.w("Notification expired: ${e.message}", e)
                // Notification has expired - user may see it was removed or marked expired in the app
            } catch (e: NotificationNotFoundException) {
                diagnosticLogger.w("Notification not found: ${e.message}", e)
                // Notification was not found - may have been deleted
            } catch (e: CredentialNotFoundException) {
                diagnosticLogger.w("Credential not found: ${e.message}", e)
                // Credential was not found - user needs to re-register
            } catch (e: Exception) {
                diagnosticLogger.e("Error denying notification: ${e.message}", e)
            }
        }
    }
    
    /**
     * Handles biometric authentication for the notification with the given ID.
     * This launches the BiometricPrompt activity.
     */
    private fun handleBiometricAuthentication(context: Context, notificationId: String) {
        val intent = Intent(context, BiometricPromptActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        context.startActivity(intent)
    }
}
