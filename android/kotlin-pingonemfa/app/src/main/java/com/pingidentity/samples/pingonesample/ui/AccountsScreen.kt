/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.VisibilityThreshold
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.CircularProgressIndicator
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
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.pingonesample.R
import com.pingidentity.samples.pingonesample.data.PingOneViewModel
import com.pingidentity.samples.pingonesample.ui.components.AccountCard
import com.pingidentity.samples.pingonesample.ui.components.OtpBox
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive

/**
 * Main screen showing registered accounts and their TOTP codes.
 * Provides a FAB to navigate to the QR scanner for adding new accounts.
 *
 * @param viewModel Shared [PingOneViewModel].
 * @param onScanQrCode Navigate to the QR scanner screen.
 * @param onDiagnosticLogs Navigate to the diagnostic logs screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountsScreen(
    viewModel: PingOneViewModel,
    onScanQrCode: () -> Unit,
    onDiagnosticLogs: () -> Unit = {},
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    // Trigger OTP generation once when accounts first become available
    LaunchedEffect(uiState.accounts) {
        if (uiState.accounts.isNotEmpty() && uiState.generatedCode == null) {
            viewModel.generateOtp()
        }
    }

    // Show snackbar on success message
    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearMessage()
        }
    }

    // Show snackbar on error
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    // Load accounts on first composition
    LaunchedEffect(Unit) {
        viewModel.loadAccounts()
    }

    // Countdown: derive `secsRemaining` from an absolute expiry deadline, ticking once per
    // second. Deriving from a fixed deadline (rather than decrementing a counter) means the
    // value is correct across composable re-entry — leaving and returning resumes at the
    // true remaining time.
    //
    // The effect is keyed on uiState.otpVersion so it restarts on every generateOtp()
    // outcome (success and failure). The deadline is captured once at effect-start:
    //   - Success: otpExpiresAtElapsedMs is the real SDK expiry.
    //   - Failure: otpExpiresAtElapsedMs is null; a synthetic deadline of now +
    //     DEFAULT_OTP_TTL_SECONDS is captured once so the countdown actually ticks to
    //     zero and triggers a retry — returning the constant on every tick would keep
    //     secsRemaining perpetually > 0 and block generateOtp() forever.
    fun secsFromDeadline(deadlineMs: Long): Int {
        val remainingMs = deadlineMs - android.os.SystemClock.elapsedRealtime()
        return (remainingMs / 1_000L).toInt().coerceAtLeast(0)
    }
    // Seed the visible counter at composition time using the same deadline formula.
    var secsRemaining by remember(uiState.otpVersion) {
        val deadline = uiState.otpExpiresAtElapsedMs
            ?: (android.os.SystemClock.elapsedRealtime() + PingOneViewModel.DEFAULT_OTP_TTL_SECONDS * 1_000L)
        mutableIntStateOf(secsFromDeadline(deadline))
    }
    LaunchedEffect(uiState.otpVersion) {
        // Capture one fixed deadline for the lifetime of this effect invocation.
        val effectDeadline = uiState.otpExpiresAtElapsedMs
            ?: (android.os.SystemClock.elapsedRealtime() + PingOneViewModel.DEFAULT_OTP_TTL_SECONDS * 1_000L)
        secsRemaining = secsFromDeadline(effectDeadline)
        while (isActive && secsRemaining > 0) {
            delay(1_000)
            secsRemaining = secsFromDeadline(effectDeadline)
        }
        // Wait one extra second after the countdown reaches 0 so the SDK's TOTP time
        // window has rotated before we request a new code. Without this delay,
        // generateOtp() fires at the boundary and the SDK may still return the
        // previous (about-to-expire) code along with a fresh 30s countdown.
        if (isActive) delay(1_000)
        // Only kick off a refresh if one isn't already in flight and we have an account.
        // generateOtp() itself is idempotent-guarded via uiState.isRefreshingOtp.
        if (isActive && !uiState.isRefreshingOtp) {
            uiState.accounts.firstOrNull()?.let { viewModel.generateOtp() }
        }
    }

    // Overflow menu state
    var showOverflowMenu by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.app_name),
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center,
                    )
                },
                actions = {
                    IconButton(onClick = { showOverflowMenu = true }) {
                        Icon(
                            imageVector = Icons.Default.MoreVert,
                            contentDescription = stringResource(R.string.accounts_more_options),
                        )
                    }
                    DropdownMenu(
                        expanded = showOverflowMenu,
                        onDismissRequest = { showOverflowMenu = false },
                    ) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.accounts_diagnostic_logs_menu_item)) },
                            onClick = {
                                showOverflowMenu = false
                                onDiagnosticLogs()
                            },
                        )
                    }
                },
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = onScanQrCode,
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = stringResource(R.string.accounts_add_account_content_desc)
                )
            }
        },
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            when {
                uiState.isLoading && uiState.accounts.isEmpty() -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }

                uiState.accounts.isEmpty() -> {
                    EmptyAccountsMessage(
                        modifier = Modifier.align(Alignment.Center),
                        onScanQrCode = onScanQrCode,
                    )
                }

                else -> {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        // Standalone OTP box at the top
                        item(key = "otp_box") {
                            OtpBox(
                                otpInfo = uiState.generatedCode,
                                secsRemaining = secsRemaining,
                            )
                        }

                        // Section label
                        item(key = "users_label") {
                            Text(
                                text = stringResource(R.string.accounts_users_section_label),
                                style = MaterialTheme.typography.labelLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(top = 4.dp, bottom = 4.dp),
                            )
                        }

                        items(
                            items = uiState.accounts,
                            key = { it.id }
                        ) { account ->
                            AccountCard(
                                account = account,
                                modifier = Modifier.animateItem(
                                    fadeInSpec = null,
                                    fadeOutSpec = null,
                                    placementSpec = spring(
                                        stiffness = Spring.StiffnessMediumLow,
                                        visibilityThreshold = IntOffset.VisibilityThreshold
                                    )
                                )
                            )
                        }
                    }

                    // Refreshing indicator overlay
                    if (uiState.isLoading) {
                        LinearProgressIndicator(
                            modifier = Modifier
                                .fillMaxWidth()
                                .align(Alignment.TopCenter)
                        )
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Composable sub-components
// ---------------------------------------------------------------------------

@Composable
private fun EmptyAccountsMessage(
    onScanQrCode: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = Icons.Default.Person,
            contentDescription = null,
            modifier = Modifier.size(64.dp),
            tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.4f)
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = stringResource(R.string.accounts_empty_title),
            style = MaterialTheme.typography.titleLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = stringResource(R.string.accounts_empty_subtitle),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
            textAlign = TextAlign.Center
        )
    }
}


