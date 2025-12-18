/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.davinci.user
import com.pingidentity.samples.app.env.daVinci
import kotlinx.coroutines.launch

/**
 * The logout view model.
 */
class LogoutViewModel : ViewModel() {
    /**
     * Logout the user.
     *
     * @param onCompleted The callback when the logout is completed.
     */
    fun logout(onCompleted: () -> Unit) {
        viewModelScope.launch {
            //If you are using DaVinci, you can use the DaVinci user object to logout
            daVinci.user()?.logout()
            onCompleted()
        }
    }
}