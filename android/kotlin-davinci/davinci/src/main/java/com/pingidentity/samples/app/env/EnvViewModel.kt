package com.pingidentity.samples.app.env
/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import android.app.Application
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.net.toUri
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.lifecycle.AndroidViewModel
import com.pingidentity.davinci.DaVinci
import com.pingidentity.davinci.module.Oidc
import com.pingidentity.davinci.plugin.DaVinci
import com.pingidentity.davinci.user
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.OidcClientConfig
import com.pingidentity.samples.app.settingDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlin.text.split

val testConfig by lazy {
    DaVinci {
        logger = Logger.STANDARD

        // Oidc as module
        module(Oidc) {
            clientId = "<Client ID>"
            discoveryEndpoint = "<Discovery Endpoint>"
            scopes = mutableSetOf("<scope1>", "<scope2>", "...")
            redirectUri = "<Redirect URI>"
            display = "Test config"
        }
    }
}
val prodConfig by lazy {
    DaVinci {
        logger = Logger.STANDARD

        module(Oidc) {
            clientId = "<Client ID>"
            discoveryEndpoint = "<Discovery Endpoint>"
            scopes = mutableSetOf("<scope1>", "<scope2>", "...")
            redirectUri = "<Redirect URI>"
            display = "Prod config"
        }
    }
}


var daVinci: DaVinci = testConfig
lateinit var redirectUri: Uri //For Social Login redirect parameter using Auth Tab


class EnvViewModel(application: Application) : AndroidViewModel(application) {

    private val servers = listOf(testConfig, prodConfig)
    val oidcConfigs = listOf(testConfig.oidcConfig(), prodConfig.oidcConfig())
    private val context = getApplication<Application>().applicationContext

    var current by mutableStateOf(prodConfig.oidcConfig())
        private set

    init {
        CoroutineScope(Dispatchers.IO).launch {
            current = readConfigFromDataStore()
            select(current)
        }
    }

    fun select(config: OidcClientConfig) {

        val server = servers.firstOrNull {
            it.oidcConfig().clientId == config.clientId
        } ?: prodConfig

        daVinci = server

        val oidcConfig = server.oidcConfig()
        redirectUri = oidcConfig.redirectUri.toUri()


        if (current.clientId != config.clientId) {
            CoroutineScope(Dispatchers.Default).launch {
                daVinci.user()?.logout()
            }
        }

        current = config

        CoroutineScope(Dispatchers.IO).launch {
            context.settingDataStore.edit { preferences ->
                preferences[stringPreferencesKey("clientId")] = config.clientId
                preferences[stringPreferencesKey("discoveryEndpoint")] = config.discoveryEndpoint
                preferences[stringPreferencesKey("scopes")] = config.scopes.joinToString(",")
                preferences[stringPreferencesKey("redirectUri")] = config.redirectUri
            }
        }
    }

    private suspend fun readConfigFromDataStore(): OidcClientConfig {
        val preferences = context.settingDataStore.data.first()

        val clientId = preferences[stringPreferencesKey("clientId")]
        val discoveryEndpoint = preferences[stringPreferencesKey("discoveryEndpoint")]
        val scopes = preferences[stringPreferencesKey("scopes")]?.split(",")?.toMutableSet()
        val redirectUri = preferences[stringPreferencesKey("redirectUri")]

        return if (clientId != null && discoveryEndpoint != null && scopes != null && redirectUri != null) {
            config {
                this.clientId = clientId
                this.discoveryEndpoint = discoveryEndpoint
                this.scopes = scopes
                this.redirectUri = redirectUri
            }
        } else {
            daVinci.oidcConfig()
        }

    }
}

/**
 * Get the current [OidcClientConfig] from the [DaVinci] instance.
 * Cannot use Davinci.oidcClientConfig, since it required the DaVinci state to be initialized.
 */
private fun DaVinci.oidcConfig(): OidcClientConfig {
    return config.modules.first { it.config is OidcClientConfig }.config as OidcClientConfig
}

private fun config(block: OidcClientConfig.() -> Unit): OidcClientConfig {
    return OidcClientConfig().apply(block)
}