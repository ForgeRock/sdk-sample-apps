/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.example.app.centralize

import org.forgerock.android.auth.FRUser

/**
 * Centralize the state of the login process.
 * @property user FRUser? the user object.
 * @property exception Exception? the exception object.
 */
data class CentralizeState(
    var user: FRUser? = null,
    var exception: Exception? = null)