/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider

/**
 * Should avoid passing context to ViewModel
 */
class PreferenceViewModel(context: Context) : ViewModel() {

    private val sharedPreferences = context.getSharedPreferences("JourneyPreferences", Context.MODE_PRIVATE)

    fun saveJourney(journeyName: String) {
        sharedPreferences.edit().putString("lastJourney", journeyName).apply()
    }

    fun getLastJourney(): String {
        return sharedPreferences.getString("lastJourney", "Login")!!
    }

    fun saveEnv(envName: String) {
        sharedPreferences.edit().putString("env", envName).apply()
    }

    fun getLastEnv() : String {
        return sharedPreferences.getString("env", "localhost")!!
    }

    companion object {
        fun factory(
            context: Context,
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return PreferenceViewModel(context.applicationContext) as T
            }
        }
    }
}