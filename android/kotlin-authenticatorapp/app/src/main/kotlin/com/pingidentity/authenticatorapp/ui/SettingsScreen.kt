/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ListAlt
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Dns
import androidx.compose.material.icons.filled.GroupWork
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.ThemeMode
import com.pingidentity.authenticatorapp.ui.components.BackNavigationTopAppBar
import com.pingidentity.authenticatorapp.ui.components.SettingItem

/**
 * The settings screen for the Authenticator app.
 * This screen allows users to configure various settings related to the app's behavior and appearance.
 *
 * @param viewModel The ViewModel that provides the settings state and handles updates.
 * @param onDismiss Callback invoked when the user wants to exit the settings screen.
 * @param onDiagnosticLogsClick Callback invoked when the user wants to view diagnostic logs.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    viewModel: AuthenticatorViewModel,
    onDismiss: () -> Unit,
    onDiagnosticLogsClick: () -> Unit = {}
) {
    // Collect all settings as state
    val copyOtp by viewModel.copyOtp.collectAsState()
    val tapToReveal by viewModel.tapToReveal.collectAsState()
    val combineAccounts by viewModel.combineAccounts.collectAsState()
    val diagnosticLogging by viewModel.diagnosticLogging.collectAsState()
    val testMode by viewModel.testMode.collectAsState()
    val themeMode by viewModel.themeMode.collectAsState()
    
    // Dialog state for theme selection
    var showThemeDialog by remember { mutableStateOf(false) }
    
    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = "Settings",
                onBackClick = onDismiss
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Copy OTP Setting
            SettingItem(
                icon = Icons.Default.ContentCopy,
                title = "Copy OTP tokens when tapped",
                description = "To copy the OTP token to the clipboard, tap the token",
                checked = copyOtp,
                onToggle = { viewModel.setCopyOtp(it) }
            )

            HorizontalDivider()

            // Tap to Reveal Setting
            SettingItem(
                icon = Icons.Default.VisibilityOff,
                title = "Tap to reveal",
                description = "OTP codes are hidden by default. To reveal the code, tap on the card",
                checked = tapToReveal,
                onToggle = { viewModel.setTapToReveal(it) }
            )

            HorizontalDivider()

            // Theme Setting
            SettingItem(
                icon = Icons.Default.DarkMode,
                title = "Theme",
                description = "Choose between light, dark, or follow system theme: ${getThemeDisplayName(themeMode)}",
                hasNavigation = true,
                onNavigate = { showThemeDialog = true }
            )

            HorizontalDivider()

            // Combine Accounts Setting
            SettingItem(
                icon = Icons.Default.GroupWork,
                title = "Combine accounts",
                description = "Group accounts with the same issuer and account name into a single entry",
                checked = combineAccounts,
                onToggle = { viewModel.setCombineAccounts(it) }
            )

            HorizontalDivider()

            // Diagnostic Logging Setting
            SettingItem(
                icon = Icons.Default.Dns,
                title = "Enable diagnostic logging",
                description = "Automatically collect errors from the app and save in place developers can collect",
                checked = diagnosticLogging,
                onToggle = { viewModel.setDiagnosticLogging(it) }
            )
            
            // View Diagnostic Logs (only visible when diagnostic logging is enabled)
            if (diagnosticLogging) {
                SettingItem(
                    icon = Icons.AutoMirrored.Filled.ListAlt,
                    title = "View diagnostic logs",
                    description = "View and export captured diagnostic logs",
                    hasNavigation = true,
                    onNavigate = onDiagnosticLogsClick
                )
            }

            HorizontalDivider()

            // Test Mode Setting
            SettingItem(
                icon = Icons.Default.BugReport,
                title = "Enable Test mode",
                description = "Enable some developer features to test the app",
                checked = testMode,
                onToggle = { viewModel.setTestMode(it) }
            )
        }
    }
    
    // Theme selection dialog
    if (showThemeDialog) {
        ThemeSelectionDialog(
            currentTheme = themeMode,
            onThemeSelected = { selectedTheme ->
                viewModel.setThemeMode(selectedTheme)
                showThemeDialog = false
            },
            onDismiss = { showThemeDialog = false }
        )
    }
}

/**
 * Dialog for selecting the app theme
 */
@Composable
private fun ThemeSelectionDialog(
    currentTheme: ThemeMode,
    onThemeSelected: (ThemeMode) -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = {
            Text("Choose Theme")
        },
        text = {
            Column {
                ThemeMode.entries.forEach { theme ->
                    Row(
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { onThemeSelected(theme) }
                            .padding(vertical = 4.dp)
                    ) {
                        RadioButton(
                            selected = currentTheme == theme,
                            onClick = { onThemeSelected(theme) }
                        )
                        Text(
                            text = getThemeDisplayName(theme),
                            modifier = Modifier.padding(start = 8.dp)
                        )
                    }
                }
            }
        },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

/**
 * Get display name for theme mode
 */
private fun getThemeDisplayName(themeMode: ThemeMode): String {
    return when (themeMode) {
        ThemeMode.LIGHT -> "Light"
        ThemeMode.DARK -> "Dark"
        ThemeMode.SYSTEM -> "Follow System"
    }
}