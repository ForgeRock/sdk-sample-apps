/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.text.style.TextAlign
import androidx.lifecycle.viewmodel.compose.viewModel

/**
 * The Rich Authorization Requests (RFC 9396) login screen: edit `authorization_details`
 * JSON, choose the delivery path and PAR, run the login, and see the outcome before
 * inspecting the RAR token.
 *
 * @param onViewToken Navigates to the RAR Access Token screen, offered after a successful
 * login.
 */
@Composable
fun RarLogin(
    onViewToken: () -> Unit = {},
    rarLoginViewModel: RarLoginViewModel = viewModel<RarLoginViewModel>(),
) {
    val preset by rarLoginViewModel.preset.collectAsState()
    val jsonText by rarLoginViewModel.jsonText.collectAsState()
    val validationError by rarLoginViewModel.validationError.collectAsState()
    val validDetailsCount by rarLoginViewModel.validDetailsCount.collectAsState()
    val parEnabled by rarLoginViewModel.parEnabled.collectAsState()
    val delivery by rarLoginViewModel.delivery.collectAsState()
    val state by rarLoginViewModel.state.collectAsState()
    val isLoading by rarLoginViewModel.isLoading.collectAsState()

    Column(
        modifier =
            Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        when {
            isLoading -> {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    CircularProgressIndicator()
                    Spacer(Modifier.height(16.dp))
                    Text("Running RAR login…")
                }
            }

            // Captured once: `state` is a delegated read, so casting inside the branch
            // could observe a different value than the one the branch matched on.
            state is RarLoginState.Success -> {
                ResultCard(
                    icon = "✓",
                    tint = Color(0xFF2E7D32),
                    title = "Authorization Successful!",
                    message =
                        "The login completed with the configured authorization_details. " +
                            "The granted details are on the RAR token.",
                ) {
                    Button(onClick = onViewToken) {
                        Text("View RAR Access Token")
                    }
                    Button(onClick = { rarLoginViewModel.resetState() }) {
                        Text("Edit Request")
                    }
                }
            }

            state is RarLoginState.Failure -> {
                val failure = state as RarLoginState.Failure
                ResultCard(
                    icon = "✗",
                    tint = MaterialTheme.colorScheme.error,
                    title = "Authorization Failed",
                    message = failure.error.displayMessage(),
                ) {
                    Button(onClick = { rarLoginViewModel.login() }) {
                        Text("Try Again")
                    }
                    Button(onClick = { rarLoginViewModel.resetState() }) {
                        Text("Edit Request")
                    }
                }
            }

            else -> {
                StatusCard(parEnabled, delivery)

                PresetPicker(
                    presets = RarPreset.entries,
                    selected = preset,
                    onSelect = rarLoginViewModel::selectPreset,
                )

                OutlinedTextField(
                    value = jsonText,
                    onValueChange = rarLoginViewModel::updateJsonText,
                    modifier = Modifier.fillMaxWidth().height(220.dp),
                    label = { Text("authorization_details (JSON array)") },
                    isError = validationError != null,
                    supportingText = {
                        when {
                            validationError != null -> Text(validationError.orEmpty())
                            else -> validDetailsCount?.let {
                                Text("Valid — $it object(s).")
                            }
                        }
                    },
                    textStyle = MaterialTheme.typography.bodySmall.copy(fontFamily = FontFamily.Monospace),
                )

                ParToggle(parEnabled, rarLoginViewModel::setPar)

                DeliveryPicker(delivery, rarLoginViewModel::setDelivery)

                Button(
                    onClick = { rarLoginViewModel.login() },
                    modifier = Modifier.align(Alignment.End),
                    enabled = validDetailsCount != null && !isLoading,
                ) {
                    Text("Login with authorization_details")
                }
            }
        }
    }
}

/** The current PAR and delivery choice, plus the two caveats the controls don't show. */
@Composable
private fun StatusCard(parEnabled: Boolean, delivery: Delivery) {
    Card(
        elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
        modifier = Modifier.fillMaxWidth(),
        border = androidx.compose.foundation.BorderStroke(2.dp, Color.Black),
        shape = MaterialTheme.shapes.medium,
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Rich Authorization Requests", style = MaterialTheme.typography.titleMedium)
            HorizontalDivider()
            Text("PAR: ${if (parEnabled) "On" else "Off"}")
            Text("Delivery: ${delivery.displayName}")
            HorizontalDivider()
            Text(
                "The RAR token is stored separately; a new RAR login revokes only the " +
                    "previous RAR token.",
                style = MaterialTheme.typography.bodySmall,
            )
            Text(
                "PAR requires the discovery document to advertise a PAR endpoint; with PAR " +
                    "on and none advertised, the login fails.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

@Composable
private fun PresetPicker(
    presets: List<RarPreset>,
    selected: RarPreset,
    onSelect: (RarPreset) -> Unit,
) {
    Column {
        Text("Preset", style = MaterialTheme.typography.titleSmall)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            presets.forEach { preset ->
                FilterChip(
                    selected = preset == selected,
                    onClick = { onSelect(preset) },
                    label = { Text(preset.label) },
                )
            }
        }
    }
}

@Composable
private fun ParToggle(parEnabled: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Card(
        elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
        modifier = Modifier.fillMaxWidth(),
        border = androidx.compose.foundation.BorderStroke(2.dp, Color.Black),
        shape = MaterialTheme.shapes.medium,
    ) {
        Row(
            modifier = Modifier.padding(12.dp).fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("Pushed Authorization Requests (PAR)")
                Text(
                    "When on, the authorization parameters are pushed to the server before " +
                        "the redirect (RFC 9126).",
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            Switch(checked = parEnabled, onCheckedChange = onCheckedChange)
        }
    }
}

@Composable
private fun DeliveryPicker(delivery: Delivery, onSelect: (Delivery) -> Unit) {
    Card(
        elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
        modifier = Modifier.fillMaxWidth(),
        border = androidx.compose.foundation.BorderStroke(2.dp, Color.Black),
        shape = MaterialTheme.shapes.medium,
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Delivery", style = MaterialTheme.typography.titleSmall)
            SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                Delivery.entries.forEachIndexed { index, option ->
                    SegmentedButton(
                        selected = delivery == option,
                        onClick = { onSelect(option) },
                        shape = SegmentedButtonDefaults.itemShape(index, Delivery.entries.size),
                    ) {
                        Text(option.displayName)
                    }
                }
            }
            Text(
                "Per transaction sends the details for this login only; client config sets " +
                    "them on the client for every login. A per-transaction value wins over a " +
                    "config-level one.",
                style = MaterialTheme.typography.bodySmall,
            )
        }
    }
}

/** Shared composition for the success and failure outcome states. */
@Composable
private fun ResultCard(
    icon: String,
    tint: Color,
    title: String,
    message: String,
    actions: @Composable ColumnScope.() -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(icon, color = tint, style = MaterialTheme.typography.displayLarge)
        Text(title, style = MaterialTheme.typography.titleLarge, textAlign = TextAlign.Center)
        Text(
            message,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
        )
        actions()
    }
}
