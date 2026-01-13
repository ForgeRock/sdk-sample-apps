/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.env

import android.app.Application
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.net.toUri
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.lifecycle.AndroidViewModel
import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc
import com.pingidentity.journey.user
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.OidcClientConfig
import com.pingidentity.samples.journeyapp.settingDataStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/*
 * TODO
 * This configuration allows you to provide 2 different environments: testConfig and prodConfig.
 * You must provide valid information for the sample app to work.
 * (If an invalid discoveryEndpoint format is provided, the app may crash)
 *
 * The sample app uses the clientId to differentiate the environment.
 * Use a different clientId for testing.
 */

val testConfig =  Journey {
    logger = Logger.STANDARD

    serverUrl = "<Server Url>"
    realm = "<Realm>"
    cookie = "<Cookie Name>"
    // Oidc as module
    module(Oidc) {
        clientId = "<Client ID"
        discoveryEndpoint = "<Discovery Endpoint>"
        scopes = mutableSetOf("<Scope1>", "<Scope2>")
        redirectUri = "<Redirect URI>"
    }
}

val prodConfig =  Journey {
    logger = Logger.STANDARD

    serverUrl = "<Server Url>"
    realm = "<Realm>"
    cookie = "<Cookie Name>"
    // Oidc as module
    module(Oidc) {
        clientId = "<Client ID"
        discoveryEndpoint = "<Discovery Endpoint>"
        scopes = mutableSetOf("<Scope1>", "<Scope2>")
        redirectUri = "<Redirect URI>"
    }
}

var journey = testConfig
lateinit var redirectUri: Uri //For Social Login redirect parameter using Auth Tab

class EnvViewModel(application: Application) : AndroidViewModel(application) {

    private val servers = listOf(testConfig, prodConfig)
    val oidcConfigs = listOf(testConfig.oidcConfig(), prodConfig.oidcConfig())
    private val context = getApplication<Application>().applicationContext

    var current by mutableStateOf(testConfig.oidcConfig())
        private set

    init {
        CoroutineScope(Dispatchers.IO).launch {
            current = readConfigFromDataStore()
            select(current)
        }
    }

    fun select(config: OidcClientConfig) {

        val server = servers.firstOrNull { it.oidcConfig().clientId == config.clientId } ?: prodConfig

        journey = server

        val oidcConfig = server.oidcConfig()

        redirectUri = oidcConfig.redirectUri.toUri()

        if (current.clientId != config.clientId) {
            CoroutineScope(Dispatchers.Default).launch {
                journey.user()?.logout()
            }
        }

        current = oidcConfig

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
            journey.oidcConfig()
        }

    }
}

/**
 * Get the current [OidcClientConfig] from the [Journey] instance.
 * Cannot use Journey.oidcClientConfig, since it required the Journey state to be initialized.
 */
private fun Journey.oidcConfig(): OidcClientConfig {
    return config.modules.first { it.config is OidcClientConfig }.config as OidcClientConfig
}

private fun config(block: OidcClientConfig.() -> Unit): OidcClientConfig {
    return OidcClientConfig().apply(block)
}
