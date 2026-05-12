/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.notification

import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
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
import androidx.core.content.ContextCompat
import com.pingidentity.authenticatorapp.AuthenticatorApp
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.ui.theme.PingIdentityAuthenticatorTheme
import com.pingidentity.mfa.commons.exception.CredentialNotFoundException
import com.pingidentity.mfa.push.exception.NotificationExpiredException
import com.pingidentity.mfa.push.exception.NotificationNotFoundException
import com.pingidentity.mfa.push.PushClient
import kotlinx.coroutines.launch

/**
 * Activity to handle biometric authentication for push notifications.
 * Shows a biometric prompt and approves/denies the notification based on the result.
 */
class BiometricPromptActivity : AppCompatActivity() {

    private lateinit var pushClient: PushClient
    
    private val diagnosticLogger = DiagnosticLogger

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Get notification ID from intent early
        val notificationId = intent?.getStringExtra(NotificationActionReceiver.EXTRA_NOTIFICATION_ID)

        // If no notification ID, log and finish
        if (notificationId == null) {
            diagnosticLogger.w("No notification ID provided")
            finish()
            return
        }
        
        setContent {
            val context = LocalContext.current
            val coroutineScope = rememberCoroutineScope()
            var isLoading by remember { mutableStateOf(true) }
            var errorMessage by remember { mutableStateOf<String?>(null) }
            var failureMessage by remember { mutableStateOf<String?>(null) }
            
            // Initialize and handle biometric authentication
            LaunchedEffect(Unit) {
                try {
                    pushClient = AuthenticatorApp.getPushClient(application as AuthenticatorApp)
                    
                    // Check if biometric authentication is available
                    val biometricManager = BiometricManager.from(context)
                    when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
                        BiometricManager.BIOMETRIC_SUCCESS -> {
                            isLoading = false
                            showBiometricPrompt(notificationId, coroutineScope) { message ->
                                failureMessage = message
                            }
                        }
                        else -> {
                            diagnosticLogger.w("Biometric authentication not available")
                            errorMessage = "Biometric authentication not available"
                            isLoading = false
                            finish()
                        }
                    }
                } catch (e: Exception) {
                    diagnosticLogger.e("Failed to initialize PushClient: ${e.message}", e)
                    errorMessage = "Failed to initialize. Please try again."
                    isLoading = false
                    finish()
                }
            }
            
            PingIdentityAuthenticatorTheme {
                Surface {
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
                        failureMessage != null -> {
                            // Show failure message
                            Box(
                                modifier = Modifier.fillMaxSize(),
                                contentAlignment = Alignment.Center
                            ) {
                                Text(text = failureMessage!!)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     * Shows the biometric prompt on the main thread.
     */
    private fun showBiometricPrompt(
        notificationId: String, 
        coroutineScope: kotlinx.coroutines.CoroutineScope,
        onFailure: (String) -> Unit
    ) {
        val executor = ContextCompat.getMainExecutor(this)
        
        val callback = object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                super.onAuthenticationSucceeded(result)
                
                coroutineScope.launch {
                    try {
                        // Approve the notification with biometric authentication
                        val authMethod = getBiometricMethodName()
                        approveBiometricNotification(notificationId, authMethod)
                        finish()
                    } catch (e: NotificationExpiredException) {
                        diagnosticLogger.e("Notification expired: ${e.message}", e)
                        onFailure("This notification has expired and can no longer be approved.")
                    } catch (e: NotificationNotFoundException) {
                        diagnosticLogger.e("Notification not found: ${e.message}", e)
                        onFailure("This notification is no longer available.")
                    } catch (e: CredentialNotFoundException) {
                        diagnosticLogger.e("Credential not found: ${e.message}", e)
                        onFailure("Credential not found. Please register again.")
                    } catch (e: Exception) {
                        diagnosticLogger.e("Failed to process approval: ${e.message}", e)
                        onFailure("Failed to approve notification: ${e.message}")
                    }
                }
            }
            
            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                super.onAuthenticationError(errorCode, errString)
                diagnosticLogger.w("Authentication error: $errString")
                
                // Show error message for non-cancellation errors
                if (errorCode != BiometricPrompt.ERROR_USER_CANCELED && 
                    errorCode != BiometricPrompt.ERROR_CANCELED &&
                    errorCode != BiometricPrompt.ERROR_NEGATIVE_BUTTON) {
                    onFailure("Authentication error: $errString")
                } else {
                    finish()
                }
            }
            
            override fun onAuthenticationFailed() {
                super.onAuthenticationFailed()
                diagnosticLogger.w("Authentication failed")
                onFailure("Biometric authentication failed. Please try again.")
            }
        }
        
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("Authenticate")
            .setSubtitle("Confirm your identity to approve the authentication request")
            .setNegativeButtonText("Cancel")
            .setConfirmationRequired(true)
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG)
            .build()
        
        val biometricPrompt = BiometricPrompt(this, executor, callback)
        biometricPrompt.authenticate(promptInfo)
    }
    
    /**
     * Determines the biometric method name from the authentication result.
     * Note: Android's BiometricPrompt API doesn't directly expose which method was used.
     * This implementation checks device capabilities to make an educated guess.
     */
    private fun getBiometricMethodName(): String {
        // Check device features to determine likely biometric method
        val packageManager = packageManager
        
        val hasFingerprint = packageManager.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)
        val hasFace = packageManager.hasSystemFeature(PackageManager.FEATURE_FACE)
        val hasIris = packageManager.hasSystemFeature(PackageManager.FEATURE_IRIS)
        
        return when {
            // If only one type is available, likely that was used
            hasFingerprint && !hasFace && !hasIris -> "fingerprint"
            hasFace && !hasFingerprint && !hasIris -> "face"
            hasIris && !hasFingerprint && !hasFace -> "iris"
            
            // If multiple are available, fingerprint is most common default
            hasFingerprint -> "fingerprint"
            hasFace -> "face"
            
            // Fallback for unknown or generic biometric
            else -> "biometric"
        }
    }
    
    /**
     * Approves the notification with biometric authentication.
     */
    private suspend fun approveBiometricNotification(notificationId: String, authMethod: String) {
        try {
            pushClient.approveBiometricNotification(notificationId, authMethod)
        } catch (e: Exception) {
            diagnosticLogger.e("Error approving biometric notification: ${e.message}", e)
            throw e
        }
    }

}
