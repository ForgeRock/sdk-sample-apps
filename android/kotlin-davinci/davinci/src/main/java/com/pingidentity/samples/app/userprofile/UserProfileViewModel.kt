/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.userprofile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.pingidentity.davinci.user
import com.pingidentity.oidc.OidcError
import com.pingidentity.samples.app.davinci.daVinci
import com.pingidentity.utils.Result.Failure
import com.pingidentity.utils.Result.Success
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * The user profile view model. Provides method to retrieve the user profile.
 */
class UserProfileViewModel : ViewModel() {
    var state = MutableStateFlow(UserProfileState())
        private set

    /**
     * Get the user profile.
     */
    fun userinfo() {
        viewModelScope.launch {
            daVinci.user()?.let { user ->
                when (val result = user.userinfo(false)) {
                    is Failure ->
                        state.update { s ->
                            val exception = when(val oidcError = result.value as? OidcError) {
                                is OidcError.ApiError -> Throwable(oidcError.message)
                                is OidcError.AuthorizeError -> oidcError.cause
                                is OidcError.NetworkError -> oidcError.cause
                                is OidcError.Unknown -> oidcError.cause
                                else -> IllegalStateException("Unexpected OidcError type: ${result.value}")
                            }
                            s.copy(user = null, error = exception)
                        }

                    is Success ->
                        state.update { s ->
                            s.copy(user = result.value, error = null)
                        }
                }
            }
        }
    }
}
