/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.samples.oidc.app.centralize.web
import kotlinx.coroutines.launch

class LogoutViewModel : ViewModel() {
    fun logout(onCompleted: () -> Unit) {
        viewModelScope.launch {
            web.user()?.logout()
            onCompleted()
        }
    }
}