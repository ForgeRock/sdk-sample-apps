/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccessTime
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.data.NotificationStatus

/**
 * Status indicator for push notifications.
 */
@Composable
fun StatusIndicator(status: NotificationStatus) {
    val (icon, color, label) = when (status) {
        NotificationStatus.PENDING -> Triple(
            Icons.Default.AccessTime,
            MaterialTheme.colorScheme.tertiary,
            "Pending"
        )
        NotificationStatus.APPROVED -> Triple(
            Icons.Default.CheckCircle,
            MaterialTheme.colorScheme.primary,
            "Approved"
        )
        NotificationStatus.DENIED -> Triple(
            Icons.Outlined.Close,
            MaterialTheme.colorScheme.error,
            "Denied"
        )
        NotificationStatus.EXPIRED -> Triple(
            Icons.Default.Error,
            MaterialTheme.colorScheme.onSurfaceVariant,
            "Expired"
        )
    }

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(32.dp)
            .background(color = color.copy(alpha = 0.1f), shape = CircleShape)
            .padding(4.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = color,
            modifier = Modifier.size(16.dp)
        )
    }
}