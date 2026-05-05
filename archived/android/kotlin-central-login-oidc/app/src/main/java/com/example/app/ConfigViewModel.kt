/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


package com.example.app

import android.app.Application
import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.dataStore
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import org.forgerock.android.auth.FRAuth
import org.forgerock.android.auth.Logger
import java.io.InputStream
import java.io.OutputStream

/**
 * ConfigViewModel to handle the configuration process.
 * @property application Application the application context.
 */
class ConfigViewModel(private val application: Application) : AndroidViewModel(application) {

    private val dataStore = application.pingConfigDataStore
    var isLoading = MutableStateFlow(false)
        private set

    var pingFlow = MutableStateFlow(PingConfig())  // MutableStateFlow to control state updates
        private set

    init {
        viewModelScope.launch {
            // Initialize pingFlow after fetching the last saved state
            val initialValue = dataStore.data.first() // Fetch the initial value
            emitPingConfig(initialValue, true)

        }
    }

    /**
     * Fetch the last saved PingConfig from DataStore
     */
    suspend fun updatePingConfig(pingConfig: PingConfig) {
        emitPingConfig(pingConfig)
    }

    /**
     * Save the PingConfig to DataStore
     * @param pingConfig PingConfig the ping config.
     */
    suspend fun savePingConfig(pingConfig: PingConfig) {
        val updatedConfig = PingConfig(
            discoveryEndpoint = pingConfig.discoveryEndpoint,
            oauthClientId = pingConfig.oauthClientId,
            oauthRedirectUri = pingConfig.oauthRedirectUri,
            oauthSignOutRedirectUri = pingConfig.oauthSignOutRedirectUri,
            oauthScope = pingConfig.oauthScope
        )

        isLoading.value = true
        dataStore.updateData { updatedConfig }
        emitPingConfig(updatedConfig, true)
        isLoading.value = false
    }

    /**
     * Reset the PingConfig to default values
     */
    suspend fun resetPingConfig() {
        isLoading.value = true
        val defaultConfig = PingConfig()  // Reset to default config
        dataStore.updateData {
            defaultConfig
        }
        emitPingConfig(defaultConfig)
        isLoading.value = false
    }

    /**
     * Emit the PingConfig to the MutableStateFlow
     * @param pingConfig PingConfig the ping config.
     * @param start Boolean start the configuration.
     */
    private suspend fun emitPingConfig(pingConfig: PingConfig, start: Boolean = false) {
        pingFlow.value = pingConfig
        if (start) {
            startConfig(pingConfig)
        }
    }

    /**
     * Start the configuration process
     * @param pingConfig PingConfig the ping config.
     */
    private suspend fun startConfig(pingConfig: PingConfig) {
        val frOptions = pingConfig.toFROptions()
        try {
            isLoading.value = true
            val option = frOptions.discover(frOptions.server.url)
            FRAuth.start(application, option)
            isLoading.value = false
        } catch (e: Exception) {
            isLoading.value = false
            Logger.error("PingConfig", e, "Discovery failed from PingOne .well-known endpoint: ${frOptions.server.url}.\n" +
                    "Message: ${e.message}")
        }

    }

    companion object {
        /**
         * Factory to create the ConfigViewModel
         * @param application Application the application context.
         */
        fun factory(
            application: Application,
        ): ViewModelProvider.Factory = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                return ConfigViewModel(application) as T
            }
        }
    }
}

/**
 * Get the PingConfig DataStore
 */
private val Context.pingConfigDataStore: DataStore<PingConfig> by dataStore(
    fileName = "ping_config.json",
    serializer = PingConfigSerializer
)

/**
 * PingConfigSerializer to handle the serialization process.
 */
object PingConfigSerializer : androidx.datastore.core.Serializer<PingConfig> {
    override val defaultValue: PingConfig = PingConfig()

    override suspend fun readFrom(input: InputStream): PingConfig {
        return try {
            Json.decodeFromString(PingConfig.serializer(), input.readBytes().decodeToString())
        } catch (e: Exception) {
            throw e
        }
    }

    override suspend fun writeTo(t: PingConfig, output: OutputStream) {
        withContext(Dispatchers.IO) {
            output.write(Json.encodeToString(PingConfig.serializer(), t).encodeToByteArray())
        }

    }
}