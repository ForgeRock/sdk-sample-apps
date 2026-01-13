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
import com.pingidentity.device.binding.journey.DeviceBindingCallback
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.launch

/**
 * ViewModel wrapper for the DeviceBindingCallback with internal PIN collection
 * coordinated through Compose state instead of passing a pinCollector outward.
 */
class DeviceBindingCallbackViewModel(
    val callback: DeviceBindingCallback,
) : ViewModel() {

    var isLoading by mutableStateOf(false)
        private set

    /**
     * Non-null while the UI must display a PIN dialog.
     */
    var activePinPrompt: Prompt? by mutableStateOf(null)
        private set

    private var pinDeferred: CompletableDeferred<CharArray>? = null

    /**
     * Start binding. The PIN dialog will be triggered by updating activePinPrompt.
     */
    fun bind(
        deviceName: String,
        onCompleted: (Result<*>) -> Unit
    ) {
        if (isLoading) return
        viewModelScope.launch {
            isLoading = true
            val result = callback.bind {
                this.deviceName = deviceName
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
                    //pinCollector = { prompt -> collectPin(prompt) }
                }
                biometricAuthenticatorConfig {
                    keyGenParameterSpec {
                        //setUnlockedDeviceRequired(true)
                        //setUserAuthenticationValidWhileOnBody(true)
                        //setUserPresenceRequired(true)
                        //setIsStrongBoxBacked(false)
                        //setInvalidatedByBiometricEnrollment(false)
                    }
                }


            }.onFailure {
            }
            isLoading = false
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

    companion object {
        fun factory(callback: DeviceBindingCallback): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T {
                    return DeviceBindingCallbackViewModel(callback) as T
                }
            }
    }
}
