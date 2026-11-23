/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Tag
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.pingidentity.pingonemfa.otp.OtpCodeInfo
import com.pingidentity.samples.pingonesample.R

/**
 * Standalone card showing the current one-time passcode (OTP) and a live countdown.
 *
 * Intended to be displayed above the accounts list. A [Tag] icon is shown on the left
 * inside a white rounded square, vertically centered alongside the OTP content.
 *
 * The countdown is driven by [secsRemaining], which the parent decrements every second
 * and resets by fetching a new OTP when it reaches zero.
 *
 * @param otpInfo The current [OtpCodeInfo] from the SDK, or null if not yet available.
 * @param secsRemaining Live seconds remaining until the OTP refreshes, ticked by the parent.
 * @param modifier Optional [Modifier] applied to the card container.
 */
@Composable
fun OtpBox(
    otpInfo: OtpCodeInfo?,
    secsRemaining: Int,
    modifier: Modifier = Modifier,
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
        ),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            // Tag icon in a white rounded square
            Box(
                modifier = Modifier
                    .size(52.dp)
                    .background(Color.White, shape = RoundedCornerShape(10.dp)),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    imageVector = Icons.Default.Tag,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(32.dp),
                )
            }

            Spacer(modifier = Modifier.width(16.dp))

            // OTP content — start-aligned
            Column(
                modifier = Modifier.weight(1f),
                horizontalAlignment = Alignment.Start,
            ) {
                Text(
                    text = stringResource(R.string.otp_box_title),
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                )
                Spacer(modifier = Modifier.height(8.dp))

                if (otpInfo != null) {
                    Text(
                        text = otpInfo.code,
                        style = MaterialTheme.typography.displaySmall,
                        color = MaterialTheme.colorScheme.onSurface,
                        letterSpacing = 6.sp,
                    )
                    Spacer(modifier = Modifier.height(6.dp))

                    Text(
                        text = stringResource(R.string.otp_box_refreshes_in, secsRemaining),
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (secsRemaining <= 5)
                            MaterialTheme.colorScheme.error
                        else
                            MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                } else {
                    Text(
                        text = "—",
                        style = MaterialTheme.typography.displaySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
                    )
                }
            }
        }
    }
}
