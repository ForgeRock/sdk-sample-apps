/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.centralize

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.OidcWeb
import com.pingidentity.oidc.module.Oidc
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

//TODO Update configuration
val web by lazy {
    OidcWeb {
        logger = Logger.STANDARD
        module(Oidc) {
            clientId = "<Client ID>"
            discoveryEndpoint = "<Discovery Endpoint>"
            scopes = mutableSetOf("<scope1>", "<scope2>", "...")
            redirectUri = "<Redirect URI>"
        }
    }
}

class CentralizeLoginViewModel : ViewModel() {
    var state = MutableStateFlow(CentralizeState())
        private set

    fun login() {
        viewModelScope.launch {
            web.authorize {
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
