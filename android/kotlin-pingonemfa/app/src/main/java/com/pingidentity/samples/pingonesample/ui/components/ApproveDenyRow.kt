/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.pingonesample.R

/**
 * A row with a Deny button on the left and an Approve button on the right.
 * Used for DEFAULT push notification type.
 */
@Composable
fun ApproveDenyRow(onApprove: () -> Unit, onDeny: () -> Unit) {
    Row(
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier.fillMaxWidth()
    ) {
        OutlinedButton(
            onClick = onDeny,
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = MaterialTheme.colorScheme.error
            )
        ) {
            Text(stringResource(R.string.system_notification_deny))
        }

        Spacer(modifier = Modifier.width(16.dp))

        Button(onClick = onApprove) {
            Text(stringResource(R.string.system_notification_approve))
        }
    }
}
