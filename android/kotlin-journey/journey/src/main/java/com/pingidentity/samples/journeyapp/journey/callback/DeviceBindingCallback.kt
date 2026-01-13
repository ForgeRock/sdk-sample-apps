/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import android.os.Build
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.pingidentity.device.binding.Prompt

@Composable
fun DeviceBindingCallback(
    viewModel: DeviceBindingCallbackViewModel,
    onNext: () -> Unit
) {
    val currentOnCompleted by rememberUpdatedState(onNext)
    var deviceName by remember { mutableStateOf(Build.MODEL) }

    // PIN Dialog (shown when ViewModel requests it)
    viewModel.activePinPrompt?.let { prompt ->
        PinCollectorDialog(
            prompt = prompt,
            onPinEntered = { pin ->
                viewModel.submitPin(pin.toCharArray())
            },
            onCancelled = {
                viewModel.cancelPin()
            }
        )
    }

    Box(
        modifier = Modifier
            .padding(4.dp)
            .fillMaxSize()
            .wrapContentSize(Alignment.TopStart)
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (viewModel.isLoading) {
                CircularProgressIndicator()
            }
        }
        Column(
            modifier = Modifier
                .fillMaxWidth()
        ) {
            OutlinedTextField(
                modifier = Modifier,
                value = deviceName,
                onValueChange = { value -> deviceName = value },
                label = { Text("Device Name") },
            )
            Spacer(modifier = Modifier.height(8.dp))
            Button(
                modifier = Modifier.align(Alignment.End),
                enabled = !viewModel.isLoading,
                onClick = {
                    viewModel.bind(
                        deviceName = deviceName
                    ) { result ->
                        result.onFailure {
                            it.printStackTrace()
                        }
                        currentOnCompleted()
                    }
                }
            ) {
                Text(if (viewModel.isLoading) "Binding..." else "Continue")
            }
        }
    }
}


@Composable
fun PinCollectorDialog(
    prompt: Prompt,
    onPinEntered: (String) -> Unit,
    onCancelled: () -> Unit
) {
    var pin by remember { mutableStateOf("") }
    var showPin by remember { mutableStateOf(false) }

    Dialog(
        onDismissRequest = onCancelled,
        properties = DialogProperties(
            dismissOnBackPress = true,
            dismissOnClickOutside = false
        )
    ) {
        Card(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surface,
                contentColor = MaterialTheme.colorScheme.onSurface
            ),
            shape = MaterialTheme.shapes.large
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Title
                if (prompt.title.isNotEmpty()) {
                    Text(
                        text = prompt.title,
                        style = MaterialTheme.typography.headlineSmall,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                // Subtitle
                if (prompt.subtitle.isNotEmpty()) {
                    Text(
                        text = prompt.subtitle,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }

                // Description
                if (prompt.description.isNotEmpty()) {
                    Text(
                        text = prompt.description,
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }

                // PIN Input Field
                OutlinedTextField(
                    value = pin,
                    onValueChange = { pin = it },
                    label = {
                        Text(
                            text = "Enter PIN",
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    },
                    modifier = Modifier.fillMaxWidth(),
                    visualTransformation = if (showPin) VisualTransformation.None else PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = MaterialTheme.colorScheme.primary,
                        unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                        focusedTextColor = MaterialTheme.colorScheme.onSurface,
                        unfocusedTextColor = MaterialTheme.colorScheme.onSurface
                    ),
                    trailingIcon = {
                        IconButton(onClick = { showPin = !showPin }) {
                            Icon(
                                imageVector = if (showPin) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                                contentDescription = if (showPin) "Hide PIN" else "Show PIN",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    },
                    singleLine = true,
                    shape = MaterialTheme.shapes.medium
                )

                // Buttons
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Cancel Button
                    TextButton(
                        onClick = onCancelled,
                        colors = ButtonDefaults.textButtonColors(
                            contentColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        Text("Cancel")
                    }

                    Spacer(modifier = Modifier.width(8.dp))

                    // Confirm Button
                    Button(
                        onClick = {
                            if (pin.isNotEmpty()) {
                                onPinEntered(pin)
                            }
                        },
                        enabled = pin.isNotEmpty(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary,
                            contentColor = MaterialTheme.colorScheme.onPrimary,
                            disabledContainerColor = MaterialTheme.colorScheme.surfaceVariant,
                            disabledContentColor = MaterialTheme.colorScheme.onSurfaceVariant
                        ),
                        shape = MaterialTheme.shapes.medium
                    ) {
                        Text("Confirm")
                    }
                }
            }
        }
    }
}