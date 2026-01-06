/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.pingidentity.journey.start
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.samples.journeyapp.env.journey
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class JourneyViewModel(private var journeyName: String) : ViewModel() {

    var state = MutableStateFlow(JourneyState())
        private set

    var loading = MutableStateFlow(false)
        private set

    init {
        start()
    }

    fun next(node: ContinueNode) {
        loading.update {
            true
        }
        viewModelScope.launch {
            val next = node.next()
            state.update {
                it.copy(node = next)
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
            val next = journey.start(journeyName)

            state.update {
                it.copy(node = next)
            }
            loading.update {
                false
            }
        }
    }

    fun refresh() {
        state.update {
            it.copy(node = it.node, counter = it.counter + 1)
        }
    }

    companion object {
        fun factory(
            journeyName: String,
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return JourneyViewModel(journeyName) as T
            }
        }
    }
}
