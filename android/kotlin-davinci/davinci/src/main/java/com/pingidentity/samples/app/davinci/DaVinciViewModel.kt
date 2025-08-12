/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.samples.app.Mode
import com.pingidentity.samples.app.User
import com.pingidentity.samples.app.env.daVinci
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

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
                it.copy(node = next)
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
            User.current(Mode.DAVINCI)
            val next = daVinci.start()

            state.update {
                it.copy(node = next)
            }
            loading.update {
                false
            }
        }
    }

    /**
     * Refresh the state of the DaVinci flow.
     */
    fun refresh() {
        state.update {
            it.copy(node = it.node)
        }
    }
}
