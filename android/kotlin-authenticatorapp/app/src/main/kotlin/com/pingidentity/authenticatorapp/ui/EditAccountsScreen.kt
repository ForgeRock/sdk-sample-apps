/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.data.AccountGroup
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.ui.components.EditAccountDialog
import com.pingidentity.authenticatorapp.ui.components.EditableAccountItem
import kotlinx.coroutines.launch

/**
 * Enum representing the type of deletion for an account.
 * OATH_ONLY: Delete only OATH credentials.
 * PUSH_ONLY: Delete only Push credentials.
 * BOTH: Delete all credentials (OATH and Push).
 */
enum class DeleteType {
    OATH_ONLY, PUSH_ONLY, BOTH
}

/**
 * Composable that displays a screen for editing accounts.
 * Users can reorder accounts via move up/down buttons,
 * edit display names, and delete accounts with confirmation.
 *
 * @param viewModel The AuthenticatorViewModel providing the UI state and actions.
 * @param onDismiss Callback invoked when the user navigates back from this screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditAccountsScreen(
    viewModel: AuthenticatorViewModel,
    onDismiss: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    val coroutineScope = rememberCoroutineScope()
    
    // State for reordering
    val hapticFeedback = LocalHapticFeedback.current
    
    // State for deletion
    var accountToDelete by remember { mutableStateOf<AccountGroup?>(null) }
    var deleteType by remember { mutableStateOf<DeleteType?>(null) }
    
    // State for editing
    var accountToEdit by remember { mutableStateOf<AccountGroup?>(null) }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Edit Accounts") },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (uiState.accountGroups.isEmpty()) {
                // No accounts message
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = "No accounts to edit",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = "Add accounts from the main screen to manage them here.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            } else {
                // Account list with reordering capability
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    itemsIndexed(
                        items = uiState.accountGroups,
                        key = { _, accountGroup ->
                            // Create a unique key using issuer, account name, and all credential IDs
                            val oathIds = accountGroup.oathCredentials.map { it.id }.sorted().joinToString(",")
                            val pushIds = accountGroup.pushCredentials.map { it.id }.sorted().joinToString(",")
                            "${accountGroup.issuer}-${accountGroup.accountName}-oath:$oathIds-push:$pushIds"
                        }
                    ) { index, accountGroup ->
                        EditableAccountItem(
                            accountGroup = accountGroup,
                            onDeleteClick = { 
                                // Only allow deletion if account is not locked
                                if (!accountGroup.isLocked) {
                                    accountToDelete = accountGroup
                                    // Determine what types of credentials this account has
                                    val hasOath = accountGroup.oathCredentials.isNotEmpty()
                                    val hasPush = accountGroup.pushCredentials.isNotEmpty()
                                    deleteType = if (hasOath && hasPush) {
                                        null // Will show selection dialog
                                    } else if (hasOath) {
                                        DeleteType.OATH_ONLY
                                    } else {
                                        DeleteType.PUSH_ONLY
                                    }
                                }
                            },
                            onEditClick = { 
                                // Only allow editing if account is not locked
                                if (!accountGroup.isLocked) {
                                    accountToEdit = accountGroup
                                }
                            },
                            onMoveUp = {
                                val newList = uiState.accountGroups.toMutableList()
                                val currentIndex = newList.indexOf(accountGroup)
                                if (currentIndex > 0) {
                                    val item = newList.removeAt(currentIndex)
                                    newList.add(currentIndex - 1, item)
                                    hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                                    // Update the ViewModel with new order
                                    viewModel.updateAccountGroupOrder(newList)
                                }
                            },
                            onMoveDown = {
                                val newList = uiState.accountGroups.toMutableList()
                                val currentIndex = newList.indexOf(accountGroup)
                                if (currentIndex < newList.size - 1) {
                                    val item = newList.removeAt(currentIndex)
                                    newList.add(currentIndex + 1, item)
                                    hapticFeedback.performHapticFeedback(HapticFeedbackType.LongPress)
                                    // Update the ViewModel with new order
                                    viewModel.updateAccountGroupOrder(newList)
                                }
                            },
                            canMoveUp = index > 0,
                            canMoveDown = index < uiState.accountGroups.size - 1
                        )
                    }
                }
            }
            
            // Delete type selection dialog (when account has both OATH and Push)
            if (accountToDelete != null && deleteType == null) {
                val account = accountToDelete!!
                AlertDialog(
                    onDismissRequest = { 
                        accountToDelete = null
                        deleteType = null
                    },
                    title = { Text("Choose what to delete") },
                    text = { 
                        Column {
                            Text("This account has multiple authentication methods:")
                            if (account.oathCredentials.isNotEmpty()) {
                                Text("• ${account.oathCredentials.size} OATH credential(s)")
                            }
                            if (account.pushCredentials.isNotEmpty()) {
                                Text("• ${account.pushCredentials.size} Push credential(s)")
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            Text("What would you like to delete?")
                        }
                    },
                    confirmButton = {
                        Column(
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            if (account.oathCredentials.isNotEmpty()) {
                                Button(
                                    onClick = { deleteType = DeleteType.OATH_ONLY },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("Delete OATH Only")
                                }
                            }
                            if (account.pushCredentials.isNotEmpty()) {
                                Button(
                                    onClick = { deleteType = DeleteType.PUSH_ONLY },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("Delete Push Only")
                                }
                            }
                            Button(
                                onClick = { deleteType = DeleteType.BOTH },
                                modifier = Modifier.fillMaxWidth(),
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = MaterialTheme.colorScheme.error
                                )
                            ) {
                                Text("Delete All")
                            }
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { 
                            accountToDelete = null
                            deleteType = null
                        }) {
                            Text("Cancel")
                        }
                    }
                )
            }
            
            // Delete confirmation dialog
            if (accountToDelete != null && deleteType != null) {
                val account = accountToDelete!!
                val type = deleteType!!
                
                val (itemsToDelete, description) = when (type) {
                    DeleteType.OATH_ONLY -> Pair(
                        account.oathCredentials.size,
                        "OATH credential(s)"
                    )
                    DeleteType.PUSH_ONLY -> Pair(
                        account.pushCredentials.size,
                        "Push credential(s)"
                    )
                    DeleteType.BOTH -> Pair(
                        account.oathCredentials.size + account.pushCredentials.size,
                        "credential(s) (all authentication methods)"
                    )
                }
                
                AlertDialog(
                    onDismissRequest = { 
                        accountToDelete = null
                        deleteType = null
                    },
                    title = { Text("Confirm Deletion") },
                    text = { 
                        Text("Are you sure you want to delete $itemsToDelete $description for \"${account.issuer} - ${account.accountName}\"?")
                    },
                    confirmButton = {
                        Button(
                            onClick = {
                                coroutineScope.launch {
                                    when (type) {
                                        DeleteType.OATH_ONLY -> {
                                            account.oathCredentials.forEach { credential ->
                                                viewModel.removeOathCredential(credential.id)
                                            }
                                        }
                                        DeleteType.PUSH_ONLY -> {
                                            account.pushCredentials.forEach { credential ->
                                                viewModel.removePushCredential(credential.id)
                                            }
                                        }
                                        DeleteType.BOTH -> {
                                            account.oathCredentials.forEach { credential ->
                                                viewModel.removeOathCredential(credential.id)
                                            }
                                            account.pushCredentials.forEach { credential ->
                                                viewModel.removePushCredential(credential.id)
                                            }
                                        }
                                    }
                                    
                                    accountToDelete = null
                                    deleteType = null
                                }
                            },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Text("Delete")
                        }
                    },
                    dismissButton = {
                        TextButton(onClick = { 
                            accountToDelete = null
                            deleteType = null
                        }) {
                            Text("Cancel")
                        }
                    }
                )
            }
            
            // Edit account dialog
            accountToEdit?.let { account ->
                EditAccountDialog(
                    account = account,
                    onDismiss = { accountToEdit = null },
                    onConfirm = { newDisplayIssuer, newDisplayAccountName ->
                        coroutineScope.launch {
                            // Update OATH credentials
                            account.oathCredentials.forEach { credential ->
                                val updatedCredential = credential.copy(
                                    displayIssuer = newDisplayIssuer,
                                    displayAccountName = newDisplayAccountName
                                )
                                viewModel.updateOathCredential(updatedCredential)
                            }
                            
                            // Update Push credentials
                            account.pushCredentials.forEach { credential ->
                                val updatedCredential = credential.copy(
                                    displayIssuer = newDisplayIssuer,
                                    displayAccountName = newDisplayAccountName
                                )
                                viewModel.updatePushCredential(updatedCredential)
                            }
                            
                            accountToEdit = null
                        }
                    }
                )
            }
        }
    }
}