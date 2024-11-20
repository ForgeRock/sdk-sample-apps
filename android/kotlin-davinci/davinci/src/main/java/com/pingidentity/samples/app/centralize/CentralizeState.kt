/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.centralize

import com.pingidentity.oidc.Token
import com.pingidentity.oidc.OidcError

data class CentralizeState(
    var token: Token? = null,
    var error: OidcError? = null,
)
