/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.davinci.DaVinci
import com.pingidentity.davinci.module.Oidc
import com.pingidentity.exception.ApiException
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.FailureNode
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * The DaVinci instance.
 */
val daVinci = DaVinci {
    logger = Logger.STANDARD

    //TODO: Provide here the Server configuration. Add the PingOne server Discovery Endpoint and
    // the OAuth2.0 client details

    // Oidc as module
    module(Oidc) {
        clientId = "<Client ID>"
        discoveryEndpoint = "<Discovery Endpoint>"
        scopes = mutableSetOf("<scope1>", "<scope2>", "...")
        redirectUri = "<Redirect URI>"
    }
}

/**
 * The view model for the DaVinci app. Holds the state of the app.
 */
class DaVinciViewModel : ViewModel() {
    var state = MutableStateFlow(DaVinciState())
        private set

    var loading = MutableStateFlow(false)
        private set

    /**
     * Initialize the DaVinci flow.
     */
    init {
        start()
    }

    /**
     * Call the next node in the DaVinci flow.
     *
     * @param current The current node.
     */
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

    /**
     * Start the DaVinci flow.
     */
    fun start() {
        loading.update {
            true
        }
        viewModelScope.launch {
            val next = daVinci.start()

            if (next is FailureNode) {
                state.update {
                    it.copy(error = next.cause)
                }
            } else {
                state.update {
                    it.copy(prev = next, node = next)
                }
                loading.update {
                    false
                }
            }

        }
    }

    /**
     * Refresh the state of the DaVinci flow.
     */
    fun refresh() {
        state.update {
            it.copy(prev = it.prev, node = it.node)
        }
    }
}
