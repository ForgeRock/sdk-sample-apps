/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.NotificationStatus
import com.pingidentity.authenticatorapp.data.PushNotificationItem
import com.pingidentity.authenticatorapp.ui.components.BackNavigationTopAppBar
import com.pingidentity.authenticatorapp.ui.components.EmptyStateMessage
import com.pingidentity.authenticatorapp.ui.components.NotificationCard
import com.pingidentity.authenticatorapp.ui.components.NotificationHistoryCard

/**
 * Screen that displays a list of push notifications, grouped by pending requests and history.
 * Pending requests are shown at the top, followed by the notification history.
 * Each notification card shows issuer, account name, message, status, time ago,
 * and indicators for biometric/challenge authentication and location info.
 *
 * @param viewModel The AuthenticatorViewModel providing the UI state and actions.
 * @param onNotificationClick Callback invoked when a notification is clicked, passing the notification ID.
 * @param onDismiss Callback invoked when the user navigates back from this screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PushNotificationsScreen(
    viewModel: AuthenticatorViewModel,
    onNotificationClick: (String) -> Unit,
    onDismiss: () -> Unit
) {
    // Refresh notifications when this screen is shown
    LaunchedEffect(Unit) {
        viewModel.refreshNotifications()
    }

    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = "Push Notifications",
                onBackClick = onDismiss
            )
        }
    ) { paddingValues ->
        if (uiState.pushNotificationItems.isEmpty()) {
            EmptyStateMessage(
                title = stringResource(id = R.string.push_notifications_empty_state),
                modifier = Modifier.padding(paddingValues)
            )
        } else {
            // Sort notifications with pending first, then by date
            val sortedItems = remember(uiState.pushNotificationItems) {
                uiState.pushNotificationItems.sortedWith(
                    compareBy<PushNotificationItem> {
                        // Sort pending notifications first
                        if (it.status == NotificationStatus.PENDING) 0 else 1
                    }.thenByDescending {
                        // Then sort by creation date (newest first)
                        it.notification.createdAt.time
                    }
                )
            }

            // Group notifications by status
            val (pendingItems, historyItems) = remember(sortedItems) {
                sortedItems.partition { it.status == NotificationStatus.PENDING }
            }

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                if (pendingItems.isNotEmpty()) {
                    item {
                        Text(
                            text = stringResource(id = R.string.push_notifications_pending_requests),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                    }

                    items(pendingItems) { item ->
                        NotificationCard(
                            notificationItem = item,
                            onNotificationClick = { onNotificationClick(item.notification.id) }
                        )
                    }
                }

                if (historyItems.isNotEmpty()) {
                    item {
                        Text(
                            text = stringResource(id = R.string.push_notifications_notification_history),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        )
                    }

                    items(historyItems) { item ->
                        NotificationHistoryCard(
                            notificationItem = item,
                            onNotificationClick = { onNotificationClick(item.notification.id) }
                        )
                    }
                }
            }
        }
    }
}

