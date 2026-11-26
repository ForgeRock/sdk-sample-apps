/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import com.pingidentity.oidc.OidcError
import com.pingidentity.oidc.Token

/**
 * The state of the RAR Access Token screen.
 *
 * @property token The RAR token, or `null` when there is none (no session, load failure, or
 * after a revoke).
 * @property error The failure that prevented loading the token, if any.
 * @property message A status line for the screen, used when [token] and [error] are both
 * absent — for example "No RAR login yet" or "RAR token revoked".
 */
data class RarTokenState(
    val token: Token? = null,
    val error: OidcError? = null,
    val message: String? = null,
)
