/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.pingidentity.android.ContextProvider
import com.pingidentity.davinci.user
import com.pingidentity.oidc.OidcUser
import com.pingidentity.samples.app.centralize.oidcClient
import com.pingidentity.samples.app.davinci.daVinci
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

private val Context.settingDataStore by preferencesDataStore(
    name = "settings"
)

enum class Mode {
    DAVINCI,
    CENTRALIZE
}

object User {

    /**
     * Sets the current mode in the DataStore.
     *
     * @param mode The mode to be set (DAVINCI or CENTRALIZE).
     */
    suspend fun current(mode: Mode) = withContext(Dispatchers.IO) {
        ContextProvider.context.settingDataStore.edit { preferences ->
            preferences[PreferencesKeys.MODE] = mode.name
        }
    }

    /**
     * Retrieves the current user based on the mode stored in the DataStore.
     *
     * @return The user object corresponding to the current mode.
     */
    suspend fun user() =
        ContextProvider.context.settingDataStore.data.map {
            it[PreferencesKeys.MODE]
        }.map {
            it?.let {
                when (Mode.valueOf(it)) {
                    Mode.DAVINCI -> {
                        daVinci.user()
                    }

                    Mode.CENTRALIZE -> {
                        OidcUser(oidcClient)
                    }
                }
            } ?: daVinci.user()
        }.first()

    private object PreferencesKeys {
        val MODE = stringPreferencesKey("mode")
    }
}
