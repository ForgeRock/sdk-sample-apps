/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.pingidentity.android.ContextProvider.context
import com.pingidentity.davinci.user
import com.pingidentity.samples.app.env.daVinci
import com.pingidentity.samples.app.env.oidcWeb
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

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
        context.settingDataStore.edit { preferences ->
            preferences[PreferencesKeys.MODE] = mode.name
        }
    }

    /**
     * Retrieves the current user based on the mode stored in the DataStore.
     *
     * @return The user object corresponding to the current mode.
     */
    suspend fun user() =
        context.settingDataStore.data.map {
            it[PreferencesKeys.MODE]
        }.map {
            it?.let {
                when (Mode.valueOf(it)) {
                    Mode.DAVINCI -> {
                        daVinci.user()
                    }

                    Mode.CENTRALIZE -> {
                        oidcWeb.user()
                    }
                }
            }
        }.first()

    private object PreferencesKeys {
        val MODE = stringPreferencesKey("mode")
    }
}