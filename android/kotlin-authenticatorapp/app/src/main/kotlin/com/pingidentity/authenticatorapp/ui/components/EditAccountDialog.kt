/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.data.AccountGroup

/**
 * A dialog that allows editing the display issuer and account name for a given account.
 *
 * @param account The AccountGroup containing the original issuer and account name.
 * @param onDismiss Callback invoked when the dialog is dismissed without saving changes.
 * @param onConfirm Callback invoked with the new display issuer and account name when changes are saved.
 */
@Composable
fun EditAccountDialog(
    account: AccountGroup,
    onDismiss: () -> Unit,
    onConfirm: (String, String) -> Unit
) {
    // Use the current display names if available, otherwise fall back to original names
    val currentDisplayIssuer = account.oathCredentials.firstOrNull()?.displayIssuer
        ?: account.pushCredentials.firstOrNull()?.displayIssuer
        ?: account.issuer

    val currentDisplayAccountName = account.oathCredentials.firstOrNull()?.displayAccountName
        ?: account.pushCredentials.firstOrNull()?.displayAccountName
        ?: account.accountName

    var displayIssuer by remember { mutableStateOf(currentDisplayIssuer) }
    var displayAccountName by remember { mutableStateOf(currentDisplayAccountName) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Edit Account Display Names") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                Text(
                    text = "Edit how this account appears in the app. The original names will be preserved.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                OutlinedTextField(
                    value = displayIssuer,
                    onValueChange = { displayIssuer = it },
                    label = { Text("Display Issuer") },
                    placeholder = { Text("e.g., My Company") },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Next),
                    singleLine = true
                )

                OutlinedTextField(
                    value = displayAccountName,
                    onValueChange = { displayAccountName = it },
                    label = { Text("Display Account Name") },
                    placeholder = { Text("e.g., My Account") },
                    modifier = Modifier.fillMaxWidth(),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    singleLine = true
                )

                // Show original values for reference
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(12.dp),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "Original Values:",
                            style = MaterialTheme.typography.labelMedium,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "Issuer: ${account.issuer}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Text(
                            text = "Account: ${account.accountName}",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onConfirm(displayIssuer.trim(), displayAccountName.trim())
                },
                enabled = displayIssuer.trim().isNotEmpty() && displayAccountName.trim().isNotEmpty()
            ) {
                Text("Save Changes")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}