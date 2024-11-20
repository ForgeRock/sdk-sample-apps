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
import com.pingidentity.samples.app.Mode
import com.pingidentity.samples.app.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// Use DataStore to store the AccessToken
//val Context.dataStore: androidx.datastore.core.DataStore<AccessToken?> by dataStore("test", DataStoreSerializer())
//val dataStore = DataStoreStorage(ContextProvider.context.dataStore)

val test = DaVinci {
    logger = Logger.STANDARD

    // Oidc as module
    module(Oidc) {
        clientId = "3172d977-8fdc-4e8b-b3c5-4f3a34cb7262"
        discoveryEndpoint =
            "https://auth.test-one-pingone.com/0c6851ed-0f12-4c9a-a174-9b1bf8b438ae/as/.well-known/openid-configuration"
        scopes = mutableSetOf("openid", "email", "address")
        redirectUri = "org.forgerock.demo://oauth2redirect"
        //storage = dataStore
    }
}

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

val socialLoginTest = DaVinci {
    logger = Logger.STANDARD

    // Oidc as module
    module(Oidc) {
        clientId = "9c7767b5-3a9d-4e9c-9d65-9fc77ccfd284"
        discoveryEndpoint =
            "https://auth.pingone.com/c2a669c0-c396-4544-994d-9c6eb3fb1602/as/.well-known/openid-configuration"
        scopes = mutableSetOf("openid", "email", "address")
        redirectUri = "com.pingidentity.demo://oauth2redirect"
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
            User.current(Mode.DAVINCI)

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
