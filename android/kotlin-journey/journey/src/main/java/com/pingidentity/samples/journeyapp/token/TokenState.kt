/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.token

import com.pingidentity.oidc.OidcError
import com.pingidentity.oidc.Token

data class TokenState(
    var token: Token? = null,
    var error: OidcError? = null,
)
