/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import android.app.Activity
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.RestorePage
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.InitializationError
import com.pingidentity.authenticatorapp.data.InitializationErrorType
import kotlinx.coroutines.launch
import kotlin.system.exitProcess

/**
 * Full-screen error UI shown when database initialization fails.
 * Provides recovery options including backup restoration and destructive recovery.
 */
@Composable
fun InitializationErrorScreen(
    viewModel: AuthenticatorViewModel,
    initializationError: InitializationError
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }
    
    var showDestructiveRecoveryDialog by remember { mutableStateOf(false) }
    var isProcessing by remember { mutableStateOf(false) }
    
    Scaffold(
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // Error icon
            Icon(
                imageVector = Icons.Default.Error,
                contentDescription = "Error",
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(72.dp)
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            // Error title
            Text(
                text = "Database Error",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Error description
            Text(
                text = getErrorDescription(initializationError.type),
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Error details card
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Error Details",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = initializationError.message,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onErrorContainer
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
            
            // Recovery options
            Text(
                text = "Recovery Options",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            // Restore from backup button
            if (initializationError.canRestoreFromBackup) {
                Button(
                    onClick = {
                        isProcessing = true
                        scope.launch {
                            viewModel.attemptRestoreFromBackup()
                                .onSuccess {
                                    snackbarHostState.showSnackbar(
                                        "Backup restored successfully. Please restart the app."
                                    )
                                    // Restart the app
                                    (context as? Activity)?.let { activity ->
                                        activity.finishAffinity()
                                        exitProcess(0)
                                    }
                                }
                                .onFailure { e ->
                                    snackbarHostState.showSnackbar(
                                        "Backup restoration failed: ${e.message}"
                                    )
                                    isProcessing = false
                                }
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isProcessing
                ) {
                    Icon(
                        imageVector = Icons.Default.RestorePage,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Restore from Backup")
                }
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            // Destructive recovery button
            if (initializationError.canUseDestructiveRecovery) {
                OutlinedButton(
                    onClick = { showDestructiveRecoveryDialog = true },
                    modifier = Modifier.fillMaxWidth(),
                    enabled = !isProcessing,
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Icon(
                        imageVector = Icons.Default.DeleteForever,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.size(8.dp))
                    Text("Clear All Data and Start Fresh")
                }
            } else {
                // Show message that destructive recovery is disabled
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "Destructive Recovery Disabled",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Destructive recovery is currently disabled. You can enable it in Settings > Enable destructive database recovery.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
    }
    
    // Destructive recovery confirmation dialog
    if (showDestructiveRecoveryDialog) {
        AlertDialog(
            onDismissRequest = { showDestructiveRecoveryDialog = false },
            icon = {
                Icon(
                    imageVector = Icons.Default.DeleteForever,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.error
                )
            },
            title = {
                Text("Clear All Data?")
            },
            text = {
                Text(
                    "This will permanently delete all your accounts and credentials. " +
                    "This action cannot be undone.\n\n" +
                    "The app will restart and you'll need to add your accounts again."
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDestructiveRecoveryDialog = false
                        isProcessing = true
                        scope.launch {
                            viewModel.enableDestructiveRecoveryAndRestart()
                                .onSuccess {
                                    snackbarHostState.showSnackbar(
                                        "Destructive recovery enabled. Restarting app..."
                                    )
                                    // Restart the app
                                    (context as? Activity)?.let { activity ->
                                        activity.finishAffinity()
                                        exitProcess(0)
                                    }
                                }
                                .onFailure { e ->
                                    snackbarHostState.showSnackbar(
                                        "Failed to enable destructive recovery: ${e.message}"
                                    )
                                    isProcessing = false
                                }
                        }
                    },
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Clear All Data")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDestructiveRecoveryDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }
} }

/**
 * Gets a user-friendly description for the error type.
 */
private fun getErrorDescription(errorType: InitializationErrorType): String {
    return when (errorType) {
        InitializationErrorType.OATH_DATABASE_CORRUPTED ->
            "The OATH credentials database is corrupted and cannot be opened. " +
                    "You can try restoring from a backup or clear all data to start fresh."

        InitializationErrorType.PUSH_DATABASE_CORRUPTED ->
            "The Push notifications database is corrupted and cannot be opened. " +
                    "You can try restoring from a backup or clear all data to start fresh."

        InitializationErrorType.BOTH_DATABASES_CORRUPTED ->
            "Both OATH and Push databases are corrupted and cannot be opened. " +
                    "You can try restoring from a backup or clear all data to start fresh."

        InitializationErrorType.OATH_INITIALIZATION_FAILED ->
            "Failed to initialize the OATH credential system. " +
                    "Please try again or contact support if the problem persists."

        InitializationErrorType.PUSH_INITIALIZATION_FAILED ->
            "Failed to initialize the Push notification system. " +
                    "Please try again or contact support if the problem persists."

        InitializationErrorType.FIREBASE_CONFIGURATION_ERROR ->
            "Firebase is not configured properly. " +
                    "Push notifications will not work until this is resolved."

        InitializationErrorType.JOURNEY_INITIALIZATION_FAILED ->
            "Failed to initialize the Journey system. " +
                    "Please try again or contact support if the problem persists."

        InitializationErrorType.UNKNOWN_ERROR ->
            "An unknown error occurred during initialization. " +
                    "Please try restarting the app or contact support."
    }
}