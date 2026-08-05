/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pingidentity.pingonemfa.push.PushNotification
import com.pingidentity.pingonemfa.push.PushType
import com.pingidentity.samples.pingonesample.R
import com.pingidentity.samples.pingonesample.notification.PushDialogState
import com.pingidentity.samples.pingonesample.notification.PushNotificationViewModel
import com.pingidentity.samples.pingonesample.ui.components.ApproveDenyRow
import com.pingidentity.samples.pingonesample.ui.components.BackNavigationTopAppBar
import com.pingidentity.samples.pingonesample.ui.components.ManualNumberChallenge
import com.pingidentity.samples.pingonesample.ui.components.NumberChallengeOptions

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PushNotificationScreen(
    notification: PushNotification,
    viewModel: PushNotificationViewModel,
    onFinish: () -> Unit,
) {
    val uiState by viewModel.uiState.collectAsState()

    // Show dialog on top of the screen — success/error after approve or deny
    when (val state = uiState.dialogState) {
        is PushDialogState.Success -> AlertDialog(
            onDismissRequest = onFinish,
            title = { Text(state.title) },
            text = { Text(state.message) },
            confirmButton = {
                Button(onClick = onFinish) {
                    Text(stringResource(R.string.ok))
                }
            }
        )
        is PushDialogState.Error -> AlertDialog(
            onDismissRequest = onFinish,
            title = { Text(stringResource(R.string.error_title)) },
            text = { Text(state.message) },
            confirmButton = {
                Button(onClick = onFinish) {
                    Text(stringResource(R.string.ok))
                }
            }
        )
        PushDialogState.None -> Unit
    }

    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = stringResource(R.string.text_pingone_mfa_screen_push_title),
                onBackClick = onFinish,
            )
        },
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = notification.title ?: stringResource(R.string.system_notification_title),
                style = MaterialTheme.typography.headlineSmall,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = notification.message ?: stringResource(R.string.system_notification_content),
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(32.dp))

            if (uiState.isLoading) {
                CircularProgressIndicator()
            } else {
                when (notification.getPushType()) {
                    PushType.DEFAULT -> {
                        ApproveDenyRow(
                            onApprove = { viewModel.approve(notification) },
                            onDeny = { viewModel.deny(notification) },
                        )
                    }
                    PushType.CHALLENGE -> {
                        val options = notification.getNumbersChallenge()
                        if (options != null) {
                            NumberChallengeOptions(
                                options = options,
                                onSelected = { viewModel.approve(notification, it) },
                                onDeny = { viewModel.deny(notification) },
                            )
                        } else {
                            ManualNumberChallenge(
                                onConfirm = { number -> viewModel.approve(notification, number) },
                                onDeny = { viewModel.deny(notification) },
                            )
                        }
                    }
                    PushType.DRY -> {
                        Text(
                            text = stringResource(R.string.text_pingone_mfa_dry_push_message),
                            style = MaterialTheme.typography.bodyMedium,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(onClick = onFinish) { Text(stringResource(R.string.text_pingone_mfa_dismiss)) }
                    }
                }
            }
        }
    }
}
