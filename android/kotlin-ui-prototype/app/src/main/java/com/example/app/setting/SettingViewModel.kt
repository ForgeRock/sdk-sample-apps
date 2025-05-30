/*
 * Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
 *
 *  This software may be modified and distributed under the terms
 *  of the MIT license. See the LICENSE file for details.
 */

package com.example.app.setting

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import org.forgerock.android.auth.FRUserKeys
import org.forgerock.android.auth.Logger
import org.forgerock.android.auth.PIInitParams
import org.forgerock.android.auth.PIProtect
import org.forgerock.android.auth.SecuredSharedPreferences
import org.forgerock.android.auth.devicebind.UserKey

class SettingViewModel(context: Context) : ViewModel() {

    private val frUserKeys = FRUserKeys(context)
    val settingState = MutableStateFlow(SettingState())

    init {
        fetch(null)
    }

    fun delete(userKey: UserKey) {
        val handler = CoroutineExceptionHandler { _, t ->
            fetch(t)
        }
        viewModelScope.launch(handler) {
            frUserKeys.delete(userKey, true)
            fetch(null)
        }
    }

    fun enable() {
        settingState.update {
            it.copy(transitionState = SettingTransitionState.EnableBinding)
        }
    }

    fun updateStateToEnable() {
        settingState.update {
            it.copy(transitionState = SettingTransitionState.Enabled)
        }
    }

    fun disable() {
        frUserKeys.loadAll().forEach {
            delete(it)
        }
        settingState.update {
            it.copy(transitionState = SettingTransitionState.Disabled)
        }
    }
    suspend fun initViewModel(context: Context) {
        try {
            val params =
                PIInitParams(
                    envId = "02fb4743-189a-4bc7-9d6c-a919edfe6447",
                    isBehavioralDataCollection = false,
                    isConsoleLogEnabled = true,
                )
            PIProtect.start(context, params)
            Logger.info("Settings Protect", "Initialize succeeded")
        } catch (e: Exception) {
            Logger.error("Initialize Error", e.message)
            throw e
        }
    }
    private fun fetch(t: Throwable?) {

        val state: SettingTransitionState = if (frUserKeys.loadAll().isNotEmpty()) {
            SettingTransitionState.Enabled
        } else {
            SettingTransitionState.Disabled
        }

        settingState.update {
            it.copy(transitionState = state)
        }
    }

    fun sspTest(context: Context) {
        val ssp = SecuredSharedPreferences(context, "SampleTest", "SampleTestKeyAlias")
        viewModelScope.launch(Dispatchers.IO) {
            for (i in 0..100) {
                save(ssp, "key$i", "value$i")
                Logger.debug("1STORAGE", "key$i -" + get(ssp, "key$i"))
            }
        }
        viewModelScope.launch(Dispatchers.IO) {
            for (i in 0..100) {
                save(ssp, "key$i", "value$i")
                Logger.debug("2STORAGE", "key$i -" + get(ssp, "key$i"))
            }
        }
        viewModelScope.launch(Dispatchers.IO) {
            for (i in 0..100) {
                save(ssp, "key$i", "value$i")
                Logger.debug("3STORAGE", "key$i -" + get(ssp, "key$i"))
            }
        }
        viewModelScope.launch(Dispatchers.IO) {
            for (i in 0..100) {
                save(ssp, "key$i", "value$i")
                Logger.debug("4STORAGE", "key$i -" + get(ssp, "key$i"))
            }
        }
    }

    private fun save(
        ssp: SecuredSharedPreferences,
        key: String,
        value: String,
    ) {
        ssp.edit().putString(key, value).commit()
    }

    private fun get(
        ssp: SecuredSharedPreferences,
        key: String,
    ): String? {
        return ssp.getString(key, null)
    }

    companion object {
        fun factory(
            context: Context
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return SettingViewModel(context.applicationContext) as T
            }
        }
    }
}