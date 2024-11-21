/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.davinci.DaVinci
import com.pingidentity.davinci.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.orchestrate.ContinueNode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

val prod = DaVinci {
    logger = Logger.STANDARD

    // Oidc as module
    module(Oidc) {
        clientId = "c12743f9-08e8-4420-a624-71bbb08e9fe1"
        discoveryEndpoint = "https://auth.pingone.ca/02fb4743-189a-4bc7-9d6c-a919edfe6447/as/.well-known/openid-configuration"
        scopes = mutableSetOf("openid", "email", "address", "phone", "profile")
        redirectUri = "org.forgerock.demo://oauth2redirect"
        //storage = dataStore
    }
}

val daVinci = prod

class DaVinciViewModel : ViewModel() {
    var state = MutableStateFlow(DaVinciState())
        private set

    var loading = MutableStateFlow(false)
        private set

    init {
        start()
    }

    fun next(current: ContinueNode) {
        loading.update {
            true
        }
        viewModelScope.launch {
            val next = current.next()
            state.update {
                it.copy(prev = current, node = next)
            }
            loading.update {
                false
            }
        }
    }

    fun start() {
        loading.update {
            true
        }
        viewModelScope.launch {

            val next = daVinci.start()

            state.update {
                it.copy(prev = next, node = next)
            }
            loading.update {
                false
            }
        }
    }

    fun refresh() {
        state.update {
            it.copy(prev = it.prev, node = it.node)
        }
    }
}
