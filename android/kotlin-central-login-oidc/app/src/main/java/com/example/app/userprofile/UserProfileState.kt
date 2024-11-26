/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


package com.example.app.userprofile

import org.json.JSONObject

/**
 * UserProfileState to handle the user profile state.
 * @property user JSONObject? the user profile.
 * @property exception Exception? the exception object.
 */
data class UserProfileState(
    var user: JSONObject? = null,
    var exception: Exception? = null)