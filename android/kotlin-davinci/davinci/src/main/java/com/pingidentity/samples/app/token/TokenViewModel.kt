/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.token

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.oidc.OidcError
import com.pingidentity.samples.app.User
import com.pingidentity.utils.Result.Failure
import com.pingidentity.utils.Result.Success
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 *  The token view model. Provides methods to get and reset the access token.
 */
class TokenViewModel : ViewModel() {
    var state = MutableStateFlow(TokenState())
        private set

    /**
     * Gets the access token.
     */
    fun accessToken() {
        viewModelScope.launch {
            User.user()?.let {
                when (val result = it.token()) {
                    is Failure -> {
                        state.update {
                            val exception = when(val oidcError = result.value as? OidcError) {
                                is OidcError.ApiError -> Throwable(oidcError.message)
                                is OidcError.AuthorizeError -> oidcError.cause
                                is OidcError.NetworkError -> oidcError.cause
                                is OidcError.Unknown -> oidcError.cause
                                else -> IllegalStateException("Unexpected OidcError type: ${result.value}")
                            }
                            it.copy(token = null, error = exception)
                        }
                    }

                    is Success -> {
                        state.update {
                            it.copy(token = result.value, error = null)
                        }
                    }
                }
            } ?: run {
                state.update {
                    it.copy(token = null, error = null)
                }
            }
        }
    }

    /**
     * Resets the access token.
     */
    fun reset() {
        state.update {
            it.copy(null, null)
        }
    }
}
