/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.example.app.userprofile

import androidx.lifecycle.ViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import org.forgerock.android.auth.FRListener
import org.forgerock.android.auth.FRUser
import org.forgerock.android.auth.UserInfo

/**
 * UserProfileViewModel to handle the user profile process.
 * @property state MutableStateFlow<UserProfileState> the state of the user profile process.
 */
class UserProfileViewModel : ViewModel() {

    var state = MutableStateFlow(UserProfileState())
        private set


    init {
        userinfo()
    }

    /**
     * userinfo to get the user info.
     */
    fun userinfo() {
        FRUser.getCurrentUser()?.getUserInfo(object : FRListener<UserInfo> {
            override fun onSuccess(result: UserInfo) {
                state.update {
                    it.copy(user = result.raw, exception = null)
                }
            }

            override fun onException(e: Exception) {
                state.update {
                   it.copy(user = null, exception = e)
                }
            }
        })
    }

}