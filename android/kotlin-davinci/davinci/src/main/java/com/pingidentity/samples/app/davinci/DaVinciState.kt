/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci

import com.pingidentity.orchestrate.Node

// The counter just to ensure compose triggers recomposition.
// When [prev] and [node] are the same, the recomposition will not be triggered.
data class DaVinciState(val prev: Node? = null, val node: Node? = null, var counter: Int = 0) {
    init {
        counter++
    }
}
