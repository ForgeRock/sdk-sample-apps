/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.journey.user
import com.pingidentity.samples.journeyapp.env.journey
import kotlinx.coroutines.launch

class LogoutViewModel : ViewModel() {
    fun logout(onCompleted: () -> Unit) {
        viewModelScope.launch {
            //If you are using Journey, you can use the Journey user object to logout
            journey.user()?.logout()
        }
        onCompleted()
    }
}