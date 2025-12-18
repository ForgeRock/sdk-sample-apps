/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.token

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.davinci.user
import com.pingidentity.samples.app.env.daVinci
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
            daVinci.user()?.let {
                when (val result = it.token()) {
                    is Failure -> {
                        state.update {
                            it.copy(token = null, error = result.value)
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
     * Revoke the access token.
     */
    fun revoke() {
        viewModelScope.launch {
            daVinci.user()?.revoke()
            state.update {
                it.copy(token = null, error = null)
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            daVinci.user()?.let {
                when (val result = it.refresh()) {
                    is Failure -> {
                        state.update { state ->
                            state.copy(token = null, error = result.value)
                        }
                    }

                    is Success -> {
                        state.update { state ->
                            state.copy(token = result.value, error = null)
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

    fun reset() {
        state.update {
            it.copy(null, null)
        }
    }
}
