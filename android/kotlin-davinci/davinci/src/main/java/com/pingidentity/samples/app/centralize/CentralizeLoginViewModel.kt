/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.centralize

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.samples.app.Mode
import com.pingidentity.samples.app.User
import com.pingidentity.samples.app.env.oidcWeb
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class CentralizeLoginViewModel : ViewModel() {
    var state = MutableStateFlow(CentralizeState())
        private set

    fun login() {
        viewModelScope.launch {
            User.current(Mode.CENTRALIZE)
            oidcWeb.authorize {
            }.onSuccess { user ->
                state.update {
                    it.copy(user = user, error = null)
                }
            }.onFailure { throwable ->
                state.update {
                    it.copy(user = null, error = throwable)
                }
            }
        }
    }
}
