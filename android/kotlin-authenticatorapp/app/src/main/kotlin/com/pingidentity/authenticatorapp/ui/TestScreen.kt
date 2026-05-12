/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CleaningServices
import androidx.compose.material.icons.filled.Dashboard
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.FindInPage
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.GroupWork
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material.icons.filled.RestorePage
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Sms
import androidx.compose.material.icons.filled.Sync
import androidx.compose.material.icons.filled.Timelapse
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AccountGroup
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.BackupFileInfo
import com.pingidentity.authenticatorapp.data.DatabaseInfo
import com.pingidentity.authenticatorapp.ui.components.SettingItem
import com.pingidentity.mfa.commons.policy.BiometricAvailablePolicy
import com.pingidentity.mfa.commons.policy.DeviceTamperingPolicy

private const val LOCKING_POLICY_CUSTOM = "customPolicy"

/**
 * Screen for developer testing features.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TestScreen(
    viewModel: AuthenticatorViewModel,
    onDismiss: () -> Unit
) {
    var deviceToken by remember { mutableStateOf<String?>(null) }
    val snackbarHostState = remember { SnackbarHostState() }
    val uiState by viewModel.uiState.collectAsState()
    val destructiveRecovery by viewModel.destructiveRecovery.collectAsState()
    val autoRestoreFromBackup by viewModel.autoRestoreFromBackup.collectAsState()
    
    // Account locking dialog states
    var showAccountSelectionDialog by remember { mutableStateOf(false) }
    var selectedAccount by remember { mutableStateOf<AccountGroup?>(null) }
    var showPolicySelectionDialog by remember { mutableStateOf(false) }

    // Backup management dialog states
    var showOathBackupsDialog by remember { mutableStateOf(false) }
    var showPushBackupsDialog by remember { mutableStateOf(false) }
    var showDatabaseInfoDialog by remember { mutableStateOf(false) }
    var showDestructiveRecoveryDialog by remember { mutableStateOf(false) }
    var showAutoRestoreDialog by remember { mutableStateOf(false) }
    var oathBackups by remember { mutableStateOf<List<BackupFileInfo>>(emptyList()) }
    var pushBackups by remember { mutableStateOf<List<BackupFileInfo>>(emptyList()) }
    var databaseInfo by remember { mutableStateOf<DatabaseInfo?>(null) }

    // Handle success messages
    LaunchedEffect(uiState.message) {
        uiState.message?.let { message ->
            snackbarHostState.showSnackbar(message)
            viewModel.clearMessage()
        }
    }

    // Handle error messages
    LaunchedEffect(uiState.error) {
        uiState.error?.let { error ->
            snackbarHostState.showSnackbar(error)
            viewModel.clearError()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(id = R.string.test_screen_title)) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(id = R.string.back)
                        )
                    }
                }
            )
        },
        snackbarHost = {
            androidx.compose.material3.SnackbarHost(hostState = snackbarHostState)
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // Account actions
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = stringResource(id = R.string.test_screen_test_accounts_title),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Button(
                        onClick = { viewModel.createRandomOathAccount() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Timelapse,
                            contentDescription = stringResource(id = R.string.test_screen_create_random_oath)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(id = R.string.test_screen_create_random_oath))
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Button(
                        onClick = { viewModel.createRandomPushAccount() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Sms,
                            contentDescription = stringResource(id = R.string.test_screen_create_random_push)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(id = R.string.test_screen_create_random_push))
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Button(
                        onClick = { viewModel.createRandomCombinedMfaAccount() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.GroupWork,
                            contentDescription = stringResource(id = R.string.test_screen_create_random_mfa)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(id = R.string.test_screen_create_random_mfa))
                    }
                }
            }

            // Account locking section
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = stringResource(id = R.string.test_screen_lock_accounts_title),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Button(
                        onClick = { showAccountSelectionDialog = true },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = uiState.accountGroups.isNotEmpty()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Security,
                            contentDescription = stringResource(id = R.string.test_screen_lock_accounts_button)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(id = R.string.test_screen_lock_accounts_button))
                    }
                    
                    if (uiState.accountGroups.isEmpty()) {
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = stringResource(id = R.string.test_screen_no_accounts_available),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Device token section
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Device Token",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = deviceToken
                            ?: stringResource(id = R.string.test_screen_loading_token),
                        style = MaterialTheme.typography.bodySmall,
                        maxLines = 5,
                        overflow = TextOverflow.Ellipsis
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    Row (modifier = Modifier.fillMaxWidth()) {
                        Button(
                            onClick = {
                                viewModel.getDeviceToken { token ->
                                    deviceToken = token
                                }
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.FindInPage,
                                contentDescription = stringResource(id = R.string.test_screen_get_token_button)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(stringResource(id = R.string.test_screen_get_token_button))
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Button(
                            onClick = {
                                viewModel.forceDeviceTokenRenew()
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Sync,
                                contentDescription = stringResource(id = R.string.test_screen_refresh_token_button)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(stringResource(id = R.string.test_screen_refresh_token_button))
                        }
                    }

                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Notification actions
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = stringResource(id = R.string.test_screen_notifications_title),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Call cleanup notifications
                    Button(
                        onClick = { viewModel.cleanupNotifications() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.CleaningServices,
                            contentDescription = stringResource(id = R.string.test_screen_clean_up_button)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(stringResource(id = R.string.test_screen_clean_up_button))
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Database & Backup Management
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Text(
                        text = "Database & Backup Management",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Destructive Recovery Setting
                    SettingItem(
                        icon = Icons.Default.Warning,
                        title = "Enable destructive database recovery",
                        description = "Automatically delete and recreate corrupted databases on initialization errors. Warning: This will cause data loss if corruption occurs.",
                        checked = destructiveRecovery,
                        onToggle = { enabled ->
                            if (enabled) {
                                showDestructiveRecoveryDialog = true
                            } else {
                                viewModel.setDestructiveRecovery(false)
                            }
                        }
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Auto-Restore From Backup Setting
                    SettingItem(
                        icon = if (autoRestoreFromBackup) Icons.Default.Sync else Icons.Default.Dashboard,
                        title = "Auto-restore from backup",
                        description = if (autoRestoreFromBackup) {
                            "SDK will automatically restore from backups on database errors"
                        } else {
                            "Disabled - You will see error screen and can choose recovery method"
                        },
                        checked = autoRestoreFromBackup,
                        onToggle = { enabled ->
                            if (!enabled) {
                                showAutoRestoreDialog = true
                            } else {
                                viewModel.setAutoRestoreFromBackup(true)
                            }
                        }
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Create manual backup section
                    Button(
                        onClick = { viewModel.createManualBackups() },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Folder,
                            contentDescription = "Create Backup"
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Create Manual Backup")
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // View backups section
                    Text(
                        text = "Backup Files",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = { 
                                viewModel.getOathBackupFiles { backups ->
                                    oathBackups = backups
                                    showOathBackupsDialog = true
                                }
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Folder,
                                contentDescription = "View OATH Backups"
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("OATH", maxLines = 1)
                        }

                        Button(
                            onClick = { 
                                viewModel.getPushBackupFiles { backups ->
                                    pushBackups = backups
                                    showPushBackupsDialog = true
                                }
                            },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Folder,
                                contentDescription = "View PUSH Backups"
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("PUSH", maxLines = 1)
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Restore from backup section
                    Text(
                        text = "Restore from Backup",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = { viewModel.restoreOathFromBackup() },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.RestorePage,
                                contentDescription = "Restore OATH"
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("OATH", maxLines = 1)
                        }

                        OutlinedButton(
                            onClick = { viewModel.restorePushFromBackup() },
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(
                                imageVector = Icons.Default.RestorePage,
                                contentDescription = "Restore PUSH"
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("PUSH", maxLines = 1)
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // Error simulation section
                    Text(
                        text = "Simulate Error Scenarios",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.error
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Grid layout: 2x2 for database error simulation
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = { viewModel.simulateOathDatabaseReadOnly() },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                                Text(
                                    text = "OATH",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Read-Only",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }

                        OutlinedButton(
                            onClick = { viewModel.simulateOathDatabaseCorruption() },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                                Text(
                                    text = "OATH",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Corrupt",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        OutlinedButton(
                            onClick = { viewModel.simulatePushDatabaseReadOnly() },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                                Text(
                                    text = "Push",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Read-Only",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }

                        OutlinedButton(
                            onClick = { viewModel.simulatePushDatabaseCorruption() },
                            modifier = Modifier.weight(1f),
                            colors = ButtonDefaults.outlinedButtonColors(
                                contentColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Column(horizontalAlignment = androidx.compose.ui.Alignment.CenterHorizontally) {
                                Text(
                                    text = "Push",
                                    style = MaterialTheme.typography.labelSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "Corrupt",
                                    style = MaterialTheme.typography.bodySmall
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedButton(
                        onClick = { viewModel.clearAllBackups() },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.outlinedButtonColors(
                            contentColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Delete,
                            contentDescription = "Clear Backups"
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Clear All Backups")
                    }

                    Spacer(modifier = Modifier.height(8.dp))

                    OutlinedButton(
                        onClick = { 
                            viewModel.getDatabaseInfo { info ->
                                databaseInfo = info
                                showDatabaseInfoDialog = true
                            }
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Icon(
                            imageVector = Icons.Default.Dashboard,
                            contentDescription = "Database Info"
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("View Database Info")
                    }
                }
            }

        }
    }
    
    // Account selection dialog
    if (showAccountSelectionDialog) {
        AlertDialog(
            onDismissRequest = { showAccountSelectionDialog = false },
            title = { Text(stringResource(id = R.string.test_screen_select_account_to_lock)) },
            text = {
                Column {
                    uiState.accountGroups.forEach { accountGroup ->
                        val isLocked = accountGroup.isLocked
                        OutlinedButton(
                            onClick = {
                                selectedAccount = accountGroup
                                showAccountSelectionDialog = false
                                if (isLocked) {
                                    // Unlock immediately
                                    viewModel.unlockAccountGroup(accountGroup)
                                } else {
                                    // Show policy selection
                                    showPolicySelectionDialog = true
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 2.dp),
                            colors = if (isLocked) {
                                ButtonDefaults.outlinedButtonColors(
                                    contentColor = MaterialTheme.colorScheme.error
                                )
                            } else {
                                ButtonDefaults.outlinedButtonColors()
                            }
                        ) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = accountGroup.displayIssuer,
                                        style = MaterialTheme.typography.titleSmall
                                    )
                                    Text(
                                        text = accountGroup.displayAccountName,
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                }
                                Row(verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
                                    Icon(
                                        imageVector = if (isLocked) Icons.Default.Lock else Icons.Default.LockOpen,
                                        contentDescription = if (isLocked) "Locked" else "Unlocked",
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text(
                                        text = if (isLocked) "Locked" else "Unlocked",
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                }
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showAccountSelectionDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Policy selection dialog
    if (showPolicySelectionDialog && selectedAccount != null) {
        val policyOptions = listOf(
            BiometricAvailablePolicy.POLICY_NAME to stringResource(id = R.string.test_screen_policy_biometric),
            DeviceTamperingPolicy.POLICY_NAME to stringResource(id = R.string.test_screen_policy_tampering),
            LOCKING_POLICY_CUSTOM to stringResource(id = R.string.test_screen_policy_custom)
        )
        var selectedPolicy by remember { mutableStateOf(policyOptions[0].first) }
        
        AlertDialog(
            onDismissRequest = { 
                showPolicySelectionDialog = false
                selectedAccount = null
            },
            title = { Text(stringResource(id = R.string.test_screen_select_policy)) },
            text = {
                Column {
                    policyOptions.forEach { (policy, displayName) ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                        ) {
                            RadioButton(
                                selected = selectedPolicy == policy,
                                onClick = { selectedPolicy = policy }
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(displayName)
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        selectedAccount?.let { account ->
                            viewModel.lockAccountGroup(account, selectedPolicy)
                        }
                        showPolicySelectionDialog = false
                        selectedAccount = null
                    }
                ) {
                    Text(stringResource(id = R.string.test_screen_lock_account))
                }
            },
            dismissButton = {
                TextButton(
                    onClick = {
                        showPolicySelectionDialog = false
                        selectedAccount = null
                    }
                ) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // OATH backups dialog
    if (showOathBackupsDialog) {
        AlertDialog(
            onDismissRequest = { showOathBackupsDialog = false },
            title = { Text("OATH Backup Files") },
            text = {
                if (oathBackups.isEmpty()) {
                    Text("No backup files found")
                } else {
                    Column {
                        oathBackups.forEach { backup ->
                            Text(
                                text = "${backup.name}\n${backup.sizeBytes / 1024} KB",
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showOathBackupsDialog = false }) {
                    Text("Close")
                }
            }
        )
    }
    
    // PUSH backups dialog
    if (showPushBackupsDialog) {
        AlertDialog(
            onDismissRequest = { showPushBackupsDialog = false },
            title = { Text("PUSH Backup Files") },
            text = {
                if (pushBackups.isEmpty()) {
                    Text("No backup files found")
                } else {
                    Column {
                        pushBackups.forEach { backup ->
                            Text(
                                text = "${backup.name}\n${backup.sizeBytes / 1024} KB",
                                style = MaterialTheme.typography.bodySmall,
                                modifier = Modifier.padding(vertical = 4.dp)
                            )
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { showPushBackupsDialog = false }) {
                    Text("Close")
                }
            }
        )
    }
    
    // Destructive recovery confirmation dialog
    if (showDestructiveRecoveryDialog) {
        AlertDialog(
            onDismissRequest = { showDestructiveRecoveryDialog = false },
            icon = {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
            },
            title = {
                Text("Enable Destructive Recovery?")
            },
            text = {
                Text(
                    "WARNING: When enabled, if database corruption is detected during app initialization, " +
                    "the app will automatically delete all your credentials and start fresh.\n\n" +
                    "This helps the app recover from errors automatically, but you will lose all " +
                    "stored accounts if corruption occurs.\n\n" +
                    "This setting is intended for testing and development purposes."
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.setDestructiveRecovery(true)
                        showDestructiveRecoveryDialog = false
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Enable")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDestructiveRecoveryDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Auto-restore confirmation dialog
    if (showAutoRestoreDialog) {
        AlertDialog(
            onDismissRequest = { showAutoRestoreDialog = false },
            icon = {
                Icon(
                    imageVector = Icons.Default.Dashboard,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
            },
            title = {
                Text("Disable Auto-Restore From Backup?")
            },
            text = {
                Text(
                    "When disabled, the SDK will NOT automatically restore from backups when database errors occur.\n\n" +
                    "✓ You will see an error screen when corruption occurs\n" +
                    "✓ You can choose to manually restore from backup or use destructive recovery\n" +
                    "✓ Backups are still created and available\n\n" +
                    "This gives you better control over the recovery process and allows testing the error handling UI."
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        viewModel.setAutoRestoreFromBackup(false)
                        showAutoRestoreDialog = false
                    }
                ) {
                    Text("Disable")
                }
            },
            dismissButton = {
                TextButton(onClick = { showAutoRestoreDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
    
    // Database info dialog
    if (showDatabaseInfoDialog && databaseInfo != null) {
        AlertDialog(
            onDismissRequest = { showDatabaseInfoDialog = false },
            title = { Text("Database Information") },
            text = {
                Column {
                    Text(
                        text = "OATH Database",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text("Path: ${databaseInfo?.oathDbPath}")
                    Text("Size: ${(databaseInfo?.oathDbSize ?: 0) / 1024} KB")
                    Text("Backups: ${databaseInfo?.oathBackupCount}")
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Text(
                        text = "PUSH Database",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold
                    )
                    Text("Path: ${databaseInfo?.pushDbPath}")
                    Text("Size: ${(databaseInfo?.pushDbSize ?: 0) / 1024} KB")
                    Text("Backups: ${databaseInfo?.pushBackupCount}")
                }
            },
            confirmButton = {
                TextButton(onClick = { showDatabaseInfoDialog = false }) {
                    Text("Close")
                }
            }
        )
    }
}
