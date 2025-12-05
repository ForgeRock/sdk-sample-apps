/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.centralize

import com.pingidentity.oidc.User

data class CentralizeState(
    var user: User? = null,
    var error: Throwable? = null,
)
