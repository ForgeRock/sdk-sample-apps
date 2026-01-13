/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.userprofile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.journeyapp.json

@Composable
fun UserProfile(userProfileViewModel: UserProfileViewModel) {
    val state by userProfileViewModel.state.collectAsState()

    LaunchedEffect(true) {
        // Not relaunch when recomposition
        userProfileViewModel.userinfo()
        // Load initial device list for default device type
        userProfileViewModel.setDeviceType(state.selectedDeviceType)
    }

    // Refresh device list when device type changes
    LaunchedEffect(state.selectedDeviceType) {
        userProfileViewModel.setDeviceType(state.selectedDeviceType)
    }
    Row(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier =
                Modifier.padding(8.dp)
                    .fillMaxWidth(),
        ) {
            Card(
                elevation = CardDefaults.cardElevation(defaultElevation = 10.dp),
                modifier = Modifier.fillMaxWidth().padding(8.dp),
                shape = MaterialTheme.shapes.medium,
            ) {
                Text(
                    "First name: ${state.user?.get("name")}",
                    Modifier.fillMaxWidth().padding(4.dp)
                )
                Text(
                    "Family name: ${state.user?.get("family_name")}",
                    Modifier.fillMaxWidth().padding(4.dp)
                )
                Text("Email: ${state.user?.get("email")}", Modifier.fillMaxWidth().padding(4.dp))
                DropdownMenu(
                    expanded = false,
                    onDismissRequest = { /* No-op */ }
                ) {
                    state.deviceList.forEach { device ->
                        DropdownMenuItem(
                            text = { Text(device) },
                            onClick = { }
                        )
                    }
                }
                Button(
                    modifier = Modifier.padding(8.dp).align(Alignment.End),
                    onClick = { userProfileViewModel.toggleDeviceInfo() }
                ) {
                    Text(text = if (state.showDeviceInfo) "Hide Info" else "Show Raw User Info")
                }
                if (state.showDeviceInfo) {
                    Text(
                        modifier = Modifier.padding(4.dp),
                        text =
                            state.user?.let {
                                json.encodeToString(it)
                            } ?: state.error?.toString() ?: "No user information available",
                    )
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                Card(
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    modifier = Modifier.fillMaxWidth().padding(8.dp),
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp)
                            .selectableGroup()
                    ) {
                        Text(
                            text = "Filter by Device Type:",
                            style = MaterialTheme.typography.titleMedium,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )

                        val deviceTypes = listOf(
                            DeviceType.OATH to "OATH (TOTP/HOTP)",
                            DeviceType.PUSH to "Push Notifications",
                            DeviceType.BOUND to "Bound Devices",
                            DeviceType.WEBAUTHN to "WebAuthn/FIDO2",
                            DeviceType.PROFILE to "Profile Devices"
                        )

                        deviceTypes.forEach { (deviceType, label) ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .selectable(
                                        selected = (state.selectedDeviceType == deviceType),
                                        onClick = {
                                            userProfileViewModel.setDeviceType(
                                                deviceType
                                            )
                                        },
                                        role = Role.RadioButton
                                    )
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                RadioButton(
                                    selected = (state.selectedDeviceType == deviceType),
                                    onClick = null // onClick is handled by Row's selectable
                                )
                                Text(
                                    text = label,
                                    style = MaterialTheme.typography.bodyLarge,
                                    modifier = Modifier.padding(start = 8.dp)
                                )
                            }
                        }

                        // Show selected device type
                        Text(
                            text = "Selected: ${state.selectedDeviceType.name}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(top = 8.dp)
                        )
                    }
                }
            }

            // Device List Section
            if (state.deviceList.isNotEmpty()) {
                Card(
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    modifier = Modifier.fillMaxWidth().padding(8.dp),
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(8.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "${state.selectedDeviceType.name} Devices (${state.deviceList.size})",
                                style = MaterialTheme.typography.titleMedium,
                                modifier = Modifier.weight(1f)
                            )

                            // Refresh button
                            IconButton(
                                onClick = {
                                    userProfileViewModel.setDeviceType(state.selectedDeviceType)
                                }
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.Refresh,
                                    contentDescription = "Refresh device list",
                                    tint = MaterialTheme.colorScheme.primary
                                )
                            }
                        }

                        if (state.isLoading) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(16.dp),
                                horizontalArrangement = Arrangement.Center
                            ) {
                                CircularProgressIndicator()
                            }
                        } else {

                        LazyColumn(
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            items(state.deviceList) { deviceName ->
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 8.dp, horizontal = 4.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = deviceName,
                                        style = MaterialTheme.typography.bodyLarge,
                                        modifier = Modifier.weight(1f)
                                    )

                                    // Edit button
                                    IconButton(
                                        onClick = {
                                            userProfileViewModel.openEditDialog(deviceName)
                                        },
                                    ) {
                                        Icon(
                                            imageVector = Icons.Filled.Edit,
                                            contentDescription = "Edit device",
                                            tint = MaterialTheme.colorScheme.primary
                                        )
                                    }

                                    // Delete button
                                    IconButton(
                                        onClick = {
                                            userProfileViewModel.onDeleteDevice(deviceName)
                                        }
                                    ) {
                                        Icon(
                                            imageVector = Icons.Filled.Delete,
                                            contentDescription = "Delete device",
                                            tint = MaterialTheme.colorScheme.error
                                        )
                                    }
                                }
                                if (deviceName != state.deviceList.last()) {
                                    HorizontalDivider(
                                        modifier = Modifier.padding(horizontal = 4.dp),
                                        thickness = 1.dp,
                                        color = MaterialTheme.colorScheme.outlineVariant
                                    )
                                }
                            }
                        }
                        }
                    }
                }
            } else if (state.selectedDeviceType != DeviceType.OATH) {
                // Show empty state when a device type is selected but no devices found
                Card(
                    elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
                    modifier = Modifier.fillMaxWidth().padding(8.dp),
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Text(
                        text = "No ${state.selectedDeviceType.name} devices found",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(16.dp)
                    )
                }
            }
        }
    }

    // Edit Device Dialog
    if (state.showEditDialog) {
        EditDeviceDialog(
            currentName = state.deviceToEdit ?: "",
            newName = state.newDeviceName,
            onNameChange = { userProfileViewModel.updateNewDeviceName(it) },
            onConfirm = { userProfileViewModel.confirmEditDevice() },
            onDismiss = { userProfileViewModel.cancelEditDialog() }
        )
    }
}

@Composable
fun EditDeviceDialog(
    currentName: String,
    newName: String,
    onNameChange: (String) -> Unit,
    onConfirm: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text(text = "Edit Device Name")
        },
        text = {
            Column {
                Text(
                    text = "Current name: $currentName",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(bottom = 8.dp)
                )
                TextField(
                    value = newName,
                    onValueChange = onNameChange,
                    label = { Text("New device name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        },
        confirmButton = {
            TextButton(
                onClick = onConfirm,
                enabled = newName.trim().isNotEmpty()
            ) {
                Text("Save")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}