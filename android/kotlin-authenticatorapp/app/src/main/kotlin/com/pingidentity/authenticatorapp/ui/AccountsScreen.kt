/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.VisibilityThreshold
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.BugReport
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Keyboard
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.QrCodeScanner
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.ui.components.AccountGroupItem
import com.pingidentity.authenticatorapp.ui.components.EmptyStateMessage
import com.pingidentity.authenticatorapp.ui.components.ErrorAlertDialog
import com.pingidentity.authenticatorapp.ui.components.LoadingIndicator
import com.pingidentity.mfa.oath.OathType
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.net.URLEncoder

private const val TOTP_REFRESH_INTERVAL_MS = 30_000L

/**
 * Screen for displaying a list of accounts and push notifications.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountsScreen(
    viewModel: AuthenticatorViewModel,
    onScanQrCode: () -> Unit,
    onAddManually: () -> Unit,
    onAccountClick: (String) -> Unit,
    onNotificationsClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onAboutClick: () -> Unit,
    onEditAccountsClick: () -> Unit,
    onTestModeClick: () -> Unit = {},
    onNavigateToLogin: () -> Unit = {}
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    val coroutineScope = rememberCoroutineScope()
    
    // Collect settings state
    val copyOtpEnabled by viewModel.copyOtp.collectAsState()
    val tapToRevealEnabled by viewModel.tapToReveal.collectAsState()
    
    // State for triggering progress bar updates
    var currentTimeMillis by remember { mutableLongStateOf(System.currentTimeMillis()) }

    // Initial generation of codes (HOTP always, TOTP when missing)
    LaunchedEffect(uiState.oathCredentials) {
        uiState.oathCredentials.forEach { credential ->
            when (credential.oathType) {
                OathType.HOTP -> {
                    // Always generate HOTP codes when credentials change
                    viewModel.generateCode(credential.id)
                }
                OathType.TOTP -> {
                    // Generate TOTP codes if not locked and no code exists yet
                    if (!credential.isLocked && uiState.generatedCodes[credential.id] == null) {
                        viewModel.generateCode(credential.id)
                    }
                }
            }
        }
    }

    // Auto-refresh TOTP codes with intelligent delay
    LaunchedEffect(uiState.oathCredentials) {
        while (isActive) {
            // Get the current list of TOTP credentials
            val totpCredentials = uiState.oathCredentials.filter { it.oathType == OathType.TOTP }

            // If no TOTP credentials, just delay for a default longer period and check again.
            if (totpCredentials.isEmpty()) {
                delay(TOTP_REFRESH_INTERVAL_MS)
                continue
            }

            val currentTimeSeconds = System.currentTimeMillis() / 1000L

            // Calculate the minimum time remaining before any TOTP code expires.
            // This is period - (currentTimeSeconds % period) for each credential.
            val minRemainingTimeMillis = totpCredentials.mapNotNull { credential ->
                val periodSeconds = credential.period.toLong()
                // Ensure period is valid for TOTP (e.g., greater than 0)
                if (periodSeconds <= 0) {
                    return@mapNotNull null
                }

                // Calculate time elapsed in the current code's validity window
                val timeIntoCurrentPeriodSlot = currentTimeSeconds % periodSeconds
                // Calculate time remaining until this specific code expires
                val remainingTimeInSlotSeconds = periodSeconds - timeIntoCurrentPeriodSlot

                remainingTimeInSlotSeconds * 1000L // Convert to milliseconds
            }.minOrNull() // Find the smallest remaining time among all credentials

            // Determine the actual delay duration.
            // Use a fallback if calculation yields null (e.g., no valid periods found),
            // and ensure a minimum delay to prevent extremely rapid loops.
            val delayDuration = maxOf(1000L, minRemainingTimeMillis ?: TOTP_REFRESH_INTERVAL_MS)

            delay(delayDuration) // Wait until the soonest OTP is expected to change

            // After the delay, at least one code has likely expired or is just about to.
            // It's time to regenerate/refresh codes for all active TOTP credentials.
            // Re-filter the credentials from uiState in case the list changed during the delay.
            // (Though if uiState.oathCredentials itself changes, LaunchedEffect will restart).
            val credentialsToRefresh = uiState.oathCredentials.filter { it.oathType == OathType.TOTP }
            credentialsToRefresh.forEach { credential ->
                // Check isActive again in case the coroutine was cancelled during the delay or processing
                if (!isActive) return@forEach
                viewModel.generateCode(credential.id)
            }
        }
    }

    // Update progress bars every second for smooth countdown without regenerating codes
    LaunchedEffect(Unit) {
        while (isActive) {
            delay(1000)
            currentTimeMillis = System.currentTimeMillis() // Trigger recomposition
        }
    }

    // Show fab menu state
    var showFabMenu by remember { mutableStateOf(false) }
    
    // Show hamburger menu state
    var showHamburgerMenu by remember { mutableStateOf(false) }
    
    // Snackbar state
    val snackbarHostState = remember { SnackbarHostState() }
    
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
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Image(
                            painter = painterResource(id = R.drawable.ping_logo),
                            contentDescription = "Ping Identity Logo",
                            modifier = Modifier
                                .size(32.dp)
                                .padding(end = 4.dp)
                        )
                                                Text(text = stringResource(id = R.string.accounts_screen_title))
                    }
                },
                actions = {
                    // Actions only visible when test mode is enabled
                    val testModeEnabled by viewModel.testMode.collectAsState()
                    if (testModeEnabled) {
                        // Refresh button to manually refresh codes and check for notifications
                        IconButton(onClick = {
                            viewModel.refreshCredentials()
                            viewModel.refreshNotifications()
                        }) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = "Refresh"
                            )
                        }
                        // Test mode button
                        IconButton(onClick = { onTestModeClick() }) {
                            Icon(
                                imageVector = Icons.Default.BugReport,
                                contentDescription = "Test Mode"
                            )
                        }
                    }
                    
                    // Hamburger menu
                    Box {
                        IconButton(onClick = { showHamburgerMenu = true }) {
                            Icon(
                                imageVector = Icons.Default.MoreVert,
                                contentDescription = "Menu"
                            )
                        }
                        
                        DropdownMenu(
                            expanded = showHamburgerMenu,
                            onDismissRequest = { showHamburgerMenu = false }
                        ) {
                            // Notifications with badge
                            DropdownMenuItem(
                                text = {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.Notifications,
                                            contentDescription = null,
                                            modifier = Modifier.padding(end = 12.dp)
                                        )
                                        Text("Notifications")
                                        
                                        // Show a badge if there are pending notifications
                                        if (uiState.pushNotificationItems.isNotEmpty()) {
                                            Box(
                                                modifier = Modifier
                                                    .size(8.dp)
                                                    .background(
                                                        color = MaterialTheme.colorScheme.error,
                                                        shape = CircleShape
                                                    )
                                                    .padding(start = 8.dp)
                                            )
                                        }
                                    }
                                },
                                onClick = {
                                    showHamburgerMenu = false
                                    onNotificationsClick()
                                }
                            )
                            
                            DropdownMenuItem(
                                text = {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.Edit,
                                            contentDescription = null,
                                            modifier = Modifier.padding(end = 12.dp)
                                        )
                                        Text("Edit Accounts")
                                    }
                                },
                                onClick = {
                                    showHamburgerMenu = false
                                    onEditAccountsClick()
                                }
                            )
                            
                            DropdownMenuItem(
                                text = {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.Settings,
                                            contentDescription = null,
                                            modifier = Modifier.padding(end = 12.dp)
                                        )
                                        Text("Settings")
                                    }
                                },
                                onClick = {
                                    showHamburgerMenu = false
                                    onSettingsClick()
                                }
                            )
                            
                            DropdownMenuItem(
                                text = {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(
                                            imageVector = Icons.Default.Info,
                                            contentDescription = null,
                                            modifier = Modifier.padding(end = 12.dp)
                                        )
                                                                                Text(stringResource(id = R.string.menu_about))
                                    }
                                },
                                onClick = {
                                    showHamburgerMenu = false
                                    onAboutClick()
                                }
                            )
                        }
                    }
                }
            )
        },
        floatingActionButton = {
            Column(horizontalAlignment = Alignment.End) {
                AnimatedVisibility(
                    visible = showFabMenu,
                    enter = fadeIn(),
                    exit = fadeOut()
                ) {
                    Column(
                        horizontalAlignment = Alignment.End,
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        // Scan QR code option
                        FloatingActionButton(
                            onClick = {
                                showFabMenu = false
                                onScanQrCode()
                            },
                            modifier = Modifier.size(48.dp),
                            containerColor = MaterialTheme.colorScheme.secondaryContainer
                        ) {
                            Icon(
                                imageVector = Icons.Default.QrCodeScanner,
                                contentDescription = "Scan QR Code"
                            )
                        }
                        
                        // Manual entry option
                        FloatingActionButton(
                            onClick = {
                                showFabMenu = false
                                onAddManually()
                            },
                            modifier = Modifier.size(48.dp),
                            containerColor = MaterialTheme.colorScheme.secondaryContainer
                        ) {
                            Icon(
                                imageVector = Icons.Default.Keyboard,
                                contentDescription = "Add Manually"
                            )
                        }
                        
                        // Login option
                        FloatingActionButton(
                            onClick = {
                                showFabMenu = false
                                onNavigateToLogin()
                            },
                            modifier = Modifier.size(48.dp),
                            containerColor = MaterialTheme.colorScheme.secondaryContainer
                        ) {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = "Journey Login"
                            )
                        }
                    }
                }
                
                // Primary FAB
                FloatingActionButton(
                    onClick = { showFabMenu = !showFabMenu },
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    contentColor = MaterialTheme.colorScheme.onPrimaryContainer
                ) {
                    Icon(
                        imageVector = Icons.Default.Add,
                                                contentDescription = stringResource(id = R.string.content_description_add_account)
                    )
                }
            }
        },
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState)
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // Loading progress indicator at the top when refreshing
            if (uiState.isRefreshing) {
                LinearProgressIndicator(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                )
            }
            
            when {
                uiState.isInitialLoading -> {
                    LoadingIndicator(
                        message = stringResource(id = R.string.loading_credentials)
                    )
                }
                uiState.accountGroups.isEmpty() -> {
                    EmptyStateMessage(
                        title = "No accounts added yet",
                        subtitle = stringResource(id = R.string.accounts_empty_state_subtitle)
                    )
                }
                else -> {
                    // List of account groups
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = uiState.accountGroups,
                        key = { accountGroup ->
                            // Create a unique key using issuer, account name, and all credential IDs
                            val oathIds = accountGroup.oathCredentials.map { it.id }.sorted().joinToString(",")
                            val pushIds = accountGroup.pushCredentials.map { it.id }.sorted().joinToString(",")
                            "${accountGroup.issuer}-${accountGroup.accountName}-oath:$oathIds-push:$pushIds"
                        }
                    ) { accountGroup ->
                        AccountGroupItem(
                            accountGroup = accountGroup,
                            codes = uiState.generatedCodes,
                            onRefreshCode = { credentialId ->
                                coroutineScope.launch {
                                    viewModel.generateCode(credentialId)
                                }
                            },
                            onItemClick = { 
                                // Pass the account group issuer and account name for navigation
                                // This allows the detail screen to display all credentials for this account
                                val encodedIssuer = URLEncoder.encode(accountGroup.issuer, "UTF-8")
                                val encodedAccountName = URLEncoder.encode(accountGroup.accountName, "UTF-8")
                                onAccountClick("$encodedIssuer/$encodedAccountName")
                            },
                            onCopyToClipboard = { text, label ->
                                viewModel.copyToClipboard(context, text, label)
                            },
                            copyOtpEnabled = copyOtpEnabled,
                            tapToRevealEnabled = tapToRevealEnabled,
                            currentTimeMillis = currentTimeMillis,
                            modifier = Modifier.animateItem(
                                fadeInSpec = null, fadeOutSpec = null, placementSpec = spring(
                                    stiffness = Spring.StiffnessMediumLow,
                                    visibilityThreshold = IntOffset.VisibilityThreshold
                                )
                            )
                        )
                    }
                }
            }
            }
            
            // Error handling
            if (uiState.error != null) {
                ErrorAlertDialog(
                    errorMessage = uiState.error!!,
                    onDismiss = { viewModel.clearError() }
                )
            }
        }
    }
}