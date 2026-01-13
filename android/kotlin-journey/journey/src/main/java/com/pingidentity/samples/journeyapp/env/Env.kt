/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.env

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentHeight
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import androidx.compose.material.icons.filled.Done
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pingidentity.oidc.OidcClientConfig
import java.net.URL

@Composable
fun Env(envViewModel: EnvViewModel = viewModel<EnvViewModel>()) {

    LazyColumn(modifier = Modifier) {
        envViewModel.oidcConfigs.forEach {
            item {
                ServerSetting(
                    option = it,
                    envViewModel.current.clientId == it.clientId
                ) {
                    envViewModel.select(it)
                }
            }
        }
    }
}

@Composable
private fun ServerSetting(
    option: OidcClientConfig,
    selected: Boolean = false,
    onServerSelected: (OidcClientConfig) -> Unit
) {
    Column {
        val host = URL(option.discoveryEndpoint).host
        Row(modifier = Modifier.padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = "$host\n${option.clientId}",
                modifier = Modifier
                    .weight(1f)
                    .wrapContentHeight(),
                style = MaterialTheme.typography.titleMedium
            )
            Spacer(Modifier.width(8.dp))
            SelectServerButton(option, selected, onServerSelected)
        }
        HorizontalDivider(color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
    }
}

@Composable
private fun SelectServerButton(
    option: OidcClientConfig,
    selected: Boolean,
    onServerSelected: (OidcClientConfig) -> Unit
) {
    val icon = if (selected) Icons.Filled.Done else Icons.Filled.CheckBoxOutlineBlank
    IconButton(
        onClick = { onServerSelected(option) }) {
        Icon(icon, contentDescription = null)
    }
}