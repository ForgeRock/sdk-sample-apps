/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.token

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.samples.oidc.app.centralize.web
import com.pingidentity.utils.Result.Failure
import com.pingidentity.utils.Result.Success
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class TokenViewModel : ViewModel() {
    var state = MutableStateFlow(TokenState())
        private set

    fun accessToken() {
        viewModelScope.launch {
           web.user()?.let {
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

    fun revoke() {
        viewModelScope.launch {
            web.user()?.revoke()
            state.update {
                it.copy(token = null, error = null)
            }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            web.user()?.let {
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
