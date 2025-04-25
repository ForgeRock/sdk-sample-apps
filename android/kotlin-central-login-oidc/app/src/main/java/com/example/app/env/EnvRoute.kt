/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


package com.example.app.env

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.unit.dp
import com.example.app.ConfigViewModel
import kotlinx.coroutines.launch

/**
 * Environment configuration route
 * @param configViewModel ConfigViewModel to handle the configuration.
 * @param param Function to navigate to the next route.
 */
@Composable
fun EnvRoute(configViewModel: ConfigViewModel, param: () -> Unit) {

    val scope = rememberCoroutineScope()
    val pingConfig by configViewModel.pingFlow.collectAsState()
    val isLoading by configViewModel.isLoading.collectAsState()

    // Focus management
    val focusManager = LocalFocusManager.current
    val scrollState = rememberScrollState()
    // State for loading indicator

    Column(modifier = Modifier
        .padding(16.dp)
        .verticalScroll(scrollState)
    ) {
        OutlinedTextField(
            value = pingConfig.discoveryEndpoint,
            onValueChange = { newUrl ->
                scope.launch {
                    configViewModel.updatePingConfig(pingConfig.copy(discoveryEndpoint = newUrl))
                }
            },
            label = { Text("Discovery URL") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = pingConfig.oauthClientId,
            onValueChange = { newClientId ->
                scope.launch {
                    configViewModel.updatePingConfig(pingConfig.copy(oauthClientId = newClientId))
                }
            },
            label = { Text("OAuth Client ID") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = pingConfig.oauthRedirectUri,
            onValueChange = { newRedirectUri ->
                scope.launch {
                    configViewModel.updatePingConfig(pingConfig.copy(oauthRedirectUri = newRedirectUri))
                }
            },
            label = { Text("OAuth Redirect URI") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = pingConfig.oauthSignOutRedirectUri,
            onValueChange = { newSignOutUri ->
                scope.launch {
                    configViewModel.updatePingConfig(pingConfig.copy(oauthSignOutRedirectUri = newSignOutUri))
                }
            },
            label = { Text("OAuth Sign-Out Redirect URI (Optional)") },
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(8.dp))

        OutlinedTextField(
            value = pingConfig.oauthScope,
            onValueChange = { newScope ->
                scope.launch {
                    configViewModel.updatePingConfig(pingConfig.copy(oauthScope = newScope))
                }
            },
            label = { Text("OAuth Scope") },
            modifier = Modifier.fillMaxWidth()
        )

        OutlinedTextField(
            value = pingConfig.cookieName,
            onValueChange = { cookieName ->
                scope.launch {
                    configViewModel.updatePingConfig(pingConfig.copy(cookieName = cookieName))
                }
            },
            label = { Text("Cookie Name (Optional)") },
            modifier = Modifier.fillMaxWidth()
        )


        Spacer(modifier = Modifier.height(8.dp))

        // Show the loading indicator if isLoading is true
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.align(Alignment.CenterHorizontally),
                color = Color.DarkGray
            )
        }


        Spacer(modifier = Modifier.height(16.dp))


        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {

            Button(
                onClick = {
                    scope.launch {
                        configViewModel.savePingConfig(pingConfig)
                        param()
                        focusManager.clearFocus()
                    }
                },
                modifier = Modifier.weight(1f)
            ) {
                Text("Centralized Login")
            }

        }

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {

            Button(
                onClick = {
                    scope.launch {
                        configViewModel.resetPingConfig()
                        focusManager.clearFocus()
                    }
                },
                modifier = Modifier.weight(0.5f)
            ) {
                Text("Reset")
            }

            Button(
                onClick = {
                    scope.launch {
                        configViewModel.savePingConfig(pingConfig)
                    }
                    focusManager.clearFocus()
                },
                modifier = Modifier.weight(0.5f)
            ) {
                Text("Save")
            }
        }

        Spacer(modifier = Modifier.height(8.dp))
    }
}

