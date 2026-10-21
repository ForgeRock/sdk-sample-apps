/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.pingonesample.R

/**
 * Displays the server-provided set of numbers for a CHALLENGE push.
 * The user taps the number that matches what they see on their other device.
 * Used when [PushNotification.getNumbersChallenge] returns a non-null array.
 */
@Composable
fun NumberChallengeOptions(
    options: IntArray,
    onSelected: (Int) -> Unit,
    onDeny: () -> Unit
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = stringResource(R.string.text_pingone_mfa_select_number),
            style = MaterialTheme.typography.titleMedium
        )

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterHorizontally),
            modifier = Modifier.fillMaxWidth()
        ) {
            options.forEach { number ->
                OutlinedButton(onClick = { onSelected(number) }) {
                    Text(number.toString())
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        OutlinedButton(
            onClick = onDeny,
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = MaterialTheme.colorScheme.error
            )
        ) {
            Text(stringResource(R.string.system_notification_deny))
        }
    }
}
