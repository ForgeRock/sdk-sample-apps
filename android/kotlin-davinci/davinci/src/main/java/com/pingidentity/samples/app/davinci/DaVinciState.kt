/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci

import com.pingidentity.orchestrate.Node

/**
 * The state of the DaVinci flow. The counter just to ensure compose triggers recomposition.
 * When [prev] and [node] are the same, the recomposition will not be triggered.
 *
 * @property prev The previous node.
 * @property node The current node.
 * @property counter The counter.
 * @property error The error.
 */
data class DaVinciState(
    val prev: Node? = null,
    val node: Node? = null,
    var counter: Int = 0,
    val error: Throwable? = null) {
    init {
        counter++
    }
}
