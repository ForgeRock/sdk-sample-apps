/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.BorderStroke
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
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.pingidentity.device.binding.UserKey

@Composable
fun DeviceSigningVerifierCallback(
    viewModel: DeviceSigningVerifierCallbackViewModel,
    showChallenge: Boolean = false,
    onNext: () -> Unit
) {
    val currentOnCompleted by rememberUpdatedState(onNext)

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

    // UserKey Dialog (shown when ViewModel requests it)
    viewModel.activeUserKeyPrompt?.let { userKeys ->
        UserKeyDialog(
            userKeys = userKeys,
            onUserKeySelected = { userKey ->
                viewModel.submitUserKey(userKey)
            },
            onCancelled = {
                viewModel.cancelUserKey()
            }
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .wrapContentSize(Alignment.Center)
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

        if (showChallenge) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
            ) {
                Card(
                    elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    border = BorderStroke(2.dp, Color.Black),
                    shape = MaterialTheme.shapes.medium
                ) {
                    Text(
                        modifier = Modifier
                            .padding(4.dp),
                        text = viewModel.callback.challenge
                    )
                }

                // Show error if any
                viewModel.signError?.let { error ->
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Error: $error",
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.padding(8.dp)
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    modifier = Modifier.align(Alignment.End),
                    enabled = !viewModel.isLoading,
                    onClick = {
                        viewModel.clearError()
                        viewModel.sign { result ->
                            result.onFailure { it.printStackTrace() }
                            currentOnCompleted()
                        }
                    }
                ) {
                    Text(if (viewModel.isLoading) "Signing..." else "Approve")
                }
            }
        } else {
            LaunchedEffect(true) {
                viewModel.sign { result ->
                    result.onFailure { it.printStackTrace() }
                    currentOnCompleted()
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UserKeyDialog(
    userKeys: List<UserKey>,
    onUserKeySelected: (UserKey) -> Unit,
    onCancelled: () -> Unit
) {
    var selectedUserKey by remember { mutableStateOf<UserKey?>(null) }
    var expanded by remember { mutableStateOf(false) }

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
                Text(
                    text = "Select User Key",
                    style = MaterialTheme.typography.headlineSmall,
                    color = MaterialTheme.colorScheme.onSurface
                )

                // User Key Dropdown
                ExposedDropdownMenuBox(
                    expanded = expanded,
                    onExpandedChange = { expanded = !expanded }
                ) {
                    OutlinedTextField(
                        value = selectedUserKey?.let { "${it.userName} (${it.authType.name})" } ?: "",
                        onValueChange = {},
                        readOnly = true,
                        label = {
                            Text(
                                text = "Select User Key",
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        },
                        trailingIcon = {
                            ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .menuAnchor(MenuAnchorType.PrimaryNotEditable, true),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = MaterialTheme.colorScheme.primary,
                            unfocusedBorderColor = MaterialTheme.colorScheme.outline,
                            focusedTextColor = MaterialTheme.colorScheme.onSurface,
                            unfocusedTextColor = MaterialTheme.colorScheme.onSurface
                        ),
                        shape = MaterialTheme.shapes.medium
                    )

                    ExposedDropdownMenu(
                        expanded = expanded,
                        onDismissRequest = { expanded = false }
                    ) {
                        userKeys.forEach { userKey ->
                            DropdownMenuItem(
                                text = { Text("${userKey.userName} (${userKey.authType.name})") },
                                onClick = {
                                    selectedUserKey = userKey
                                    expanded = false
                                }
                            )
                        }
                    }
                }

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
                            selectedUserKey?.let { onUserKeySelected(it) }
                        },
                        enabled = selectedUserKey != null,
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
