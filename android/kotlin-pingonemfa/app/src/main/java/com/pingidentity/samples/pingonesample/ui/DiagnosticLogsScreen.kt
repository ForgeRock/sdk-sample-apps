/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CleaningServices
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.pingonesample.R
import com.pingidentity.samples.pingonesample.data.DiagnosticLogger
import com.pingidentity.samples.pingonesample.data.LogEntry

/**
 * Screen displaying diagnostic logs with options to share or clear them.
 *
 * Collects [DiagnosticLogger.logs] as a [androidx.compose.runtime.State] and renders each
 * [LogEntry] in a [LazyColumn]. Auto-scrolls to the bottom whenever a new entry is appended.
 *
 * @param onDismiss Called when the user taps the back arrow.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiagnosticLogsScreen(
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val logs by DiagnosticLogger.logs.collectAsState()
    val listState = rememberLazyListState()

    // Auto-scroll to the newest entry whenever the list grows.
    LaunchedEffect(logs.size) {
        if (logs.isNotEmpty()) {
            listState.animateScrollToItem(logs.size - 1)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(stringResource(R.string.diagnostic_logs_title, logs.size))
                },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = stringResource(R.string.content_description_back),
                        )
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            val shareIntent = Intent().apply {
                                action = Intent.ACTION_SEND
                                type = "text/plain"
                                putExtra(Intent.EXTRA_TEXT, DiagnosticLogger.exportLogs())
                                putExtra(
                                    Intent.EXTRA_SUBJECT,
                                    context.getString(R.string.diagnostic_logs_share_subject)
                                )
                            }
                            context.startActivity(
                                Intent.createChooser(
                                    shareIntent,
                                    context.getString(R.string.diagnostic_logs_share_chooser_title)
                                )
                            )
                        }
                    ) {
                        Icon(
                            imageVector = Icons.Default.Share,
                            contentDescription = stringResource(R.string.diagnostic_logs_share_content_desc),
                        )
                    }

                    IconButton(onClick = { DiagnosticLogger.clearLogs() }) {
                        Icon(
                            imageVector = Icons.Default.CleaningServices,
                            contentDescription = stringResource(R.string.diagnostic_logs_clear_content_desc),
                        )
                    }
                },
            )
        },
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
        ) {
            if (logs.isEmpty()) {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center,
                ) {
                    Text(
                        text = stringResource(R.string.diagnostic_logs_empty_title),
                        style = MaterialTheme.typography.bodyLarge,
                    )
                    Text(
                        text = stringResource(R.string.diagnostic_logs_empty_subtitle),
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(top = 8.dp),
                    )
                }
            } else {
                LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    items(items = logs, key = { it.id }) { logEntry ->
                        LogEntryCard(logEntry = logEntry)
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Private sub-components
// ---------------------------------------------------------------------------

/**
 * Card displaying a single [LogEntry]: timestamp + level chip in a header row,
 * message body, and an optional error block for exception details.
 */
@Composable
private fun LogEntryCard(
    logEntry: LogEntry,
    modifier: Modifier = Modifier,
) {
    val levelColor = when (logEntry.level) {
        "ERROR" -> MaterialTheme.colorScheme.error
        "WARN"  -> Color(0xFFFF9800)
        "INFO"  -> MaterialTheme.colorScheme.primary
        "DEBUG" -> MaterialTheme.colorScheme.secondary
        else    -> MaterialTheme.colorScheme.onSurface
    }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
        ) {
            // Timestamp + level chip
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = logEntry.timestamp,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontFamily = FontFamily.Monospace,
                )
                Box(
                    modifier = Modifier
                        .background(
                            color = levelColor.copy(alpha = 0.1f),
                            shape = RoundedCornerShape(4.dp),
                        )
                        .padding(horizontal = 8.dp, vertical = 2.dp),
                ) {
                    Text(
                        text = logEntry.level,
                        style = MaterialTheme.typography.labelSmall,
                        color = levelColor,
                        fontFamily = FontFamily.Monospace,
                    )
                }
            }

            // Message
            Text(
                text = logEntry.message,
                style = MaterialTheme.typography.bodyMedium,
                fontFamily = FontFamily.Monospace,
                modifier = Modifier.padding(top = 8.dp),
                maxLines = 3,
                overflow = TextOverflow.Ellipsis,
            )

            // Exception block
            logEntry.throwable?.let { throwable ->
                Text(
                    text = throwable,
                    style = MaterialTheme.typography.bodySmall,
                    fontFamily = FontFamily.Monospace,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier
                        .padding(top = 8.dp)
                        .background(
                            color = MaterialTheme.colorScheme.error.copy(alpha = 0.1f),
                            shape = RoundedCornerShape(4.dp),
                        )
                        .padding(8.dp),
                    maxLines = 5,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}
