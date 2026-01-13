/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.pingidentity.device.binding.Prompt
import com.pingidentity.device.binding.UserKey
import com.pingidentity.device.binding.journey.DeviceSigningVerifierCallback
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch

/**
 * ViewModel wrapper for the DeviceSigningVerifierCallback with signing logic
 * and state management separated from the UI.
 */
class DeviceSigningVerifierCallbackViewModel(
    val callback: DeviceSigningVerifierCallback,
) : ViewModel() {

    var isLoading by mutableStateOf(false)
        private set

    var signError by mutableStateOf<String?>(null)
        private set

    /**
     * Non-null while the UI must display a PIN dialog.
     */
    var activePinPrompt: Prompt? by mutableStateOf(null)
        private set

    /**
     * Non-null while the UI must display a UserKey selection dialog.
     */
    var activeUserKeyPrompt: List<UserKey>? by mutableStateOf(null)
        private set

    private var pinDeferred: CompletableDeferred<CharArray>? = null
    private var userKeyDeferred: CompletableDeferred<UserKey>? = null

    /**
     * Start signing process with retry logic.
     */
    fun sign(onCompleted: (Result<*>) -> Unit) {
        if (isLoading) return
        viewModelScope.launch {
            isLoading = true
            signError = null

            val result =
                // Client side retry logic (3 attempts)
                callback.sign {
                    appPinConfig {
                        pinCollector { prompt ->
                            // Trigger UI to show dialog
                            pinDeferred = CompletableDeferred()
                            activePinPrompt = prompt
                            // Suspend until user supplies PIN (or cancellation)
                            pinDeferred!!.await().also {
                                // Once consumed, clear state so dialog closes
                                activePinPrompt = null
                            }
                        }
                    }

                    userKeySelector { userKeys ->
                        // Trigger UI to show user key selection dialog
                        userKeyDeferred = CompletableDeferred()
                        activeUserKeyPrompt = userKeys
                        // Suspend until user selects a key (or cancellation)
                        userKeyDeferred!!.await().also {
                            // Once consumed, clear state so dialog closes
                            activeUserKeyPrompt = null
                        }
                    }

                    biometricAuthenticatorConfig {
                        promptInfo {
                            setConfirmationRequired(true)
                            setTitle("Biometric Authentication")
                            setSubtitle("Please authenticate with your biometric device")
                            setDescription("This app requires biometric authentication to sign")
                        }
                    }

                }

            isLoading = false
            result.onFailure { error ->
                signError = error.message ?: "Unknown signing error"
            }
            onCompleted(result)
        }
    }

    /**
     * Called by UI when user confirms a PIN.
     */
    fun submitPin(pin: CharArray) {
        pinDeferred?.takeIf { it.isActive }?.complete(pin)
    }

    /**
     * Called by UI when user cancels PIN entry.
     */
    fun cancelPin(reason: String = "User cancelled PIN entry") {
        pinDeferred?.takeIf { it.isActive }?.completeExceptionally(RuntimeException(reason))
        activePinPrompt = null
    }

    /**
     * Called by UI when user selects a UserKey.
     */
    fun submitUserKey(userKey: UserKey) {
        userKeyDeferred?.takeIf { it.isActive }?.complete(userKey)
    }

    /**
     * Called by UI when user cancels UserKey selection.
     */
    fun cancelUserKey(reason: String = "User cancelled user key selection") {
        userKeyDeferred?.takeIf { it.isActive }?.completeExceptionally(RuntimeException(reason))
        activeUserKeyPrompt = null
    }

    /**
     * Clear any existing error state.
     */
    fun clearError() {
        signError = null
    }

    companion object {
        fun factory(callback: DeviceSigningVerifierCallback): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return DeviceSigningVerifierCallbackViewModel(callback) as T
                }
            }
    }
}
