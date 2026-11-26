/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * A view model for the RAR Access Token screen: loads the token the RAR client holds,
 * exposes the `authorization_details` granted for it, and revokes it.
 *
 * The token is read from [RarClientStore]'s client on every call, because the store replaces
 * that client when its options change.
 */
class RarTokenViewModel : ViewModel() {

    private val _state = MutableStateFlow(RarTokenState())
    val state = _state.asStateFlow()

    /** Loads the RAR token and updates the state with it, an error, or a status message. */
    fun accessToken() {
        viewModelScope.launch {
            try {
                val user = RarClientStore.client.user()
                if (user == null) {
                    _state.update {
                        RarTokenState(message = "No RAR login yet. Start a RAR login first.")
                    }
                    return@launch
                }
                when (val result = user.token()) {
                    is com.pingidentity.utils.Result.Success -> {
                        _state.update { RarTokenState(token = result.value) }
                        // Only the number of granted details is logged, never the token or
                        // the details.
                        Logger.STANDARD.i(
                            "RAR AccessToken retrieved, granted authorization_details: " +
                                "${result.value.authorizationDetails?.size ?: 0}"
                        )
                    }
                    is com.pingidentity.utils.Result.Failure -> {
                        _state.update { RarTokenState(error = result.value) }
                        Logger.STANDARD.e("RAR AccessToken failed: ${result.value}")
                    }
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                // user() reads the token storage outside the SDK's own catch, so a storage
                // failure (for example an invalidated keystore key) surfaces here.
                _state.update {
                    RarTokenState(message = "Could not load the RAR token: ${e.message ?: e}")
                }
                Logger.STANDARD.e("RAR AccessToken failed: $e")
            }
        }
    }

    /**
     * Revokes the RAR token and clears it from this screen. Touches only the RAR client's
     * storage; the standard client's token and the browser session are not affected.
     */
    fun revoke() {
        viewModelScope.launch {
            try {
                RarClientStore.client.user()?.revoke()
                Logger.STANDARD.i("RAR token revoked")
                _state.update {
                    RarTokenState(message = "RAR token revoked. A new RAR login is required.")
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                _state.update {
                    RarTokenState(
                        message = "Could not revoke the RAR token: ${e.message ?: e}"
                    )
                }
                Logger.STANDARD.e("RAR revoke failed: $e")
            }
        }
    }

    /** Clears the screen back to its initial, empty state. */
    fun reset() {
        _state.update { RarTokenState() }
    }
}
