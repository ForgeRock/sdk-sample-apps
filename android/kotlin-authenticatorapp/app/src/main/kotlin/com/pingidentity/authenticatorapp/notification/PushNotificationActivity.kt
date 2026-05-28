/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.notification

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import com.pingidentity.authenticatorapp.AuthenticatorApp
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.data.PushNotificationItem
import com.pingidentity.authenticatorapp.data.createPushNotificationItem
import com.pingidentity.authenticatorapp.notification.NotificationActionReceiver.Companion.EXTRA_NOTIFICATION_ID
import com.pingidentity.authenticatorapp.ui.NotificationResponseScreen
import com.pingidentity.authenticatorapp.ui.theme.PingIdentityAuthenticatorTheme
import com.pingidentity.mfa.commons.exception.CredentialNotFoundException
import com.pingidentity.mfa.push.exception.NotificationExpiredException
import com.pingidentity.mfa.push.exception.NotificationNotFoundException
import com.pingidentity.mfa.push.PushClient
import kotlinx.coroutines.launch

/**
 * Activity to handle full-screen display of push notifications.
 * This activity is launched when a notification is received or when the user clicks on a notification.
 */
class PushNotificationActivity : ComponentActivity() {

    private lateinit var pushClient: PushClient

    private val diagnosticLogger = DiagnosticLogger

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Get notification ID from intent
        val notificationId = intent?.getStringExtra(EXTRA_NOTIFICATION_ID)

        // If no notification ID, log and finish
        if (notificationId == null) {
            diagnosticLogger.w("No notification ID provided")
            finish()
            return
        }
        
        // Set content to show notification details
        setContent {
            val context = LocalContext.current
            val coroutineScope = rememberCoroutineScope()
            var isLoading by remember { mutableStateOf(true) }
            var notificationItemState by remember { mutableStateOf<PushNotificationItem?>(null) }
            var errorMessage by remember { mutableStateOf<String?>(null) }
            
            // Load the notification when the composable is first launched
            LaunchedEffect(Unit) {
                try {
                    pushClient = AuthenticatorApp.getPushClient(application)
                    notificationItemState = loadNotification(notificationId)
                    isLoading = false
                } catch (e: Exception) {
                    diagnosticLogger.w("Error loading notification: ${e.message}")
                    errorMessage = "Failed to load notification: ${e.message}"
                    isLoading = false
                }
            }
            
            PingIdentityAuthenticatorTheme {
                Surface {
                    val currentNotificationItem = notificationItemState // Use a local copy for smart casting
                    when {
                        isLoading -> {
                            // Show loading indicator
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                CircularProgressIndicator()
                            }
                        }
                        errorMessage != null -> {
                            // Show error message
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(text = errorMessage!!)
                            }
                        }
                        currentNotificationItem != null -> {
                            // Display the unified notification screen
                            NotificationResponseScreen(
                                notificationItem = currentNotificationItem,
                                onDismiss = { finish() },
                                onApprove = {
                                    coroutineScope.launch {
                                        try {
                                            pushClient.approveNotification(notificationId)
                                                .onSuccess { finish() }
                                                .onFailure { e ->
                                                    diagnosticLogger.e("Error approving notification: ${e.message}", e)
                                                    errorMessage = when (e) {
                                                        is NotificationExpiredException -> "This notification has expired and can no longer be approved."
                                                        is NotificationNotFoundException -> "This notification is no longer available."
                                                        is CredentialNotFoundException -> "Credential not found. Please register again."
                                                        else -> "Failed to approve: ${e.message}"
                                                    }
                                                }
                                        } catch (e: Exception) {
                                            diagnosticLogger.e("Error approving notification: ${e.message}", e)
                                            errorMessage = when (e) {
                                                is NotificationExpiredException -> "This notification has expired and can no longer be approved."
                                                is NotificationNotFoundException -> "This notification is no longer available."
                                                is CredentialNotFoundException -> "Credential not found. Please register again."
                                                else -> "Failed to approve: ${e.message}"
                                            }
                                        }
                                    }
                                },
                                onBiometricApprove = {
                                    launchBiometricPrompt(notificationId)
                                },
                                onDeny = {
                                    coroutineScope.launch {
                                        try {
                                            pushClient.denyNotification(notificationId)
                                                .onSuccess { finish() }
                                                .onFailure { e ->
                                                    diagnosticLogger.e("Error denying notification: ${e.message}", e)
                                                    errorMessage = when (e) {
                                                        is NotificationExpiredException -> "This notification has expired and can no longer be denied."
                                                        is NotificationNotFoundException -> "This notification is no longer available."
                                                        is CredentialNotFoundException -> "Credential not found. Please register again."
                                                        else -> "Failed to deny: ${e.message}"
                                                    }
                                                }
                                        } catch (e: Exception) {
                                            diagnosticLogger.e("Error denying notification: ${e.message}", e)
                                            errorMessage = when (e) {
                                                is NotificationExpiredException -> "This notification has expired and can no longer be denied."
                                                is NotificationNotFoundException -> "This notification is no longer available."
                                                is CredentialNotFoundException -> "Credential not found. Please register again."
                                                else -> "Failed to deny: ${e.message}"
                                            }
                                        }
                                    }
                                },
                                onChallengeSolution = { solution ->
                                    coroutineScope.launch {
                                        try {
                                            pushClient.approveChallengeNotification(
                                                notificationId,
                                                solution
                                            ).onSuccess {
                                                finish()
                                            }.onFailure { e ->
                                                diagnosticLogger.e("Error approving with challenge: ${e.message}", e)
                                                errorMessage = when (e) {
                                                    is NotificationExpiredException -> "This notification has expired and can no longer be approved."
                                                    is NotificationNotFoundException -> "This notification is no longer available."
                                                    is CredentialNotFoundException -> "Credential not found. Please register again."
                                                    else -> "Failed to approve: ${e.message}"
                                                }
                                            }
                                        } catch (e: Exception) {
                                            diagnosticLogger.e("Error approving with challenge: ${e.message}", e)
                                            errorMessage = when (e) {
                                                is NotificationExpiredException -> "This notification has expired and can no longer be approved."
                                                is NotificationNotFoundException -> "This notification is no longer available."
                                                is CredentialNotFoundException -> "Credential not found. Please register again."
                                                else -> "Failed to approve: ${e.message}"
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Loads a notification by ID and wraps it in a PushNotificationItem
     */
    private suspend fun loadNotification(notificationId: String): PushNotificationItem? {
        return try {
            // Handle Result for getNotification
            val notificationResult = pushClient.getNotification(notificationId)
            val notification = notificationResult.getOrNull() // Extract value or null if error

            // Handle Result for getCredentials
            val credentialsResult = pushClient.getCredentials()
            val credentials = credentialsResult.getOrNull() // Extract value or null if error

            if (notification != null && credentials != null) {
                 createPushNotificationItem(credentials, notification)
            } else {
                // Log specific errors if results were failures
                notificationResult.onFailure { e -> diagnosticLogger.e( "Error fetching notification: ${e.message}", e) }
                credentialsResult.onFailure { e -> diagnosticLogger.e("Error fetching credentials: ${e.message}", e) }
                null
            }
        } catch (e: Exception) { // Catch any other synchronous exceptions
            diagnosticLogger.e("Error loading notification data", e)
            null
        }
    }

    /**
     * Launches the BiometricPromptActivity for biometric authentication.
     */
    private fun launchBiometricPrompt(notificationId: String) {
        val intent = Intent(this, BiometricPromptActivity::class.java).apply {
            putExtra(EXTRA_NOTIFICATION_ID, notificationId)
        }
        startActivity(intent)
        finish() // finish current activity before launching new one.
    }

}
