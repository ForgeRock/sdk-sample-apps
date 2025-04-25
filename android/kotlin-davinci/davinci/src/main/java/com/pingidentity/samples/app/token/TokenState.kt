/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.token

import com.pingidentity.oidc.Token
import com.pingidentity.oidc.OidcError

/**
 * The token state.
 *
 * @property token The token.
 * @property error The error.
 */
data class TokenState(
    var token: Token? = null,
    var error: Throwable? = null,
)
