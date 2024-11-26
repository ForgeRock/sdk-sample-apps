/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.example.app.token

import org.forgerock.android.auth.AccessToken

/**
 * Token state
 * @property accessToken AccessToken? the access token.
 * @property exception Throwable? the exception object.
 */
data class TokenState(
    var accessToken: AccessToken? = null,
    var exception: Throwable? = null)