/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import android.content.Context
import androidx.datastore.preferences.preferencesDataStore

internal val Context.settingDataStore by preferencesDataStore(
    name = "settings"
)