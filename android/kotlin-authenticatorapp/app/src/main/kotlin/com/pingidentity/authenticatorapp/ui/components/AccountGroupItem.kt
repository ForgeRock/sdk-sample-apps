/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Timelapse
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AccountGroup
import com.pingidentity.authenticatorapp.data.getLockMessage
import com.pingidentity.mfa.oath.OathCodeInfo
import com.pingidentity.mfa.oath.OathType

/**
 * Composable for displaying an account group item with OATH and Push credentials.
 *
 * @param accountGroup The account group containing OATH and Push credentials.
 * @param codes Map of OATH code information keyed by credential ID.
 * @param onRefreshCode Callback to refresh the OATH code for a given credential ID.
 * @param onItemClick Callback when the item is clicked.
 * @param onCopyToClipboard Callback to copy text to clipboard.
 * @param copyOtpEnabled Whether OTP copying on tap is enabled.
 * @param tapToRevealEnabled Whether tap-to-reveal is enabled.
 * @param modifier Modifier to apply to the composable.
 */
@Composable
fun AccountGroupItem(
    accountGroup: AccountGroup,
    codes: Map<String, OathCodeInfo>,
    onRefreshCode: (String) -> Unit,
    onItemClick: () -> Unit,
    onCopyToClipboard: (String, String) -> Unit = { _, _ -> },
    copyOtpEnabled: Boolean = false,
    tapToRevealEnabled: Boolean = false,
    currentTimeMillis: Long = System.currentTimeMillis(),
    modifier: Modifier = Modifier
) {
    LocalContext.current

    // Find the first TOTP code to display if available
    val firstOathCredential = accountGroup.oathCredentials.firstOrNull()
    val firstOathCode = firstOathCredential?.let { codes[it.id] }
    
    // State for tap-to-reveal functionality
    // Reset revealed state when credential is unlocked or code changes
    var isRevealed by remember(firstOathCredential?.isLocked, firstOathCode?.code) { 
        mutableStateOf(!tapToRevealEnabled || (firstOathCredential?.isLocked == false && firstOathCode != null)) 
    }

    val progress = if (firstOathCode != null && firstOathCredential != null && firstOathCredential.oathType == OathType.TOTP) {
        // Calculate real-time progress based on current time and credential period
        val currentTimeSeconds = currentTimeMillis / 1000L
        val periodSeconds = firstOathCredential.period.toLong()
        if (periodSeconds > 0) {
            val timeIntoCurrentPeriod = currentTimeSeconds % periodSeconds
            val progressValue = timeIntoCurrentPeriod.toFloat() / periodSeconds.toFloat()
            progressValue
        } else {
            0f
        }
    } else {
        0f
    }

    val hasOathCredentials = accountGroup.oathCredentials.isNotEmpty()
    val hasPushCredentials = accountGroup.pushCredentials.isNotEmpty()

    // Determine which image URL to use (use OATH first if available, otherwise Push)
    val imageUrl = when {
        firstOathCredential?.imageURL != null -> firstOathCredential.imageURL
        accountGroup.pushCredentials.firstOrNull()?.imageURL != null ->
            accountGroup.pushCredentials.first().imageURL
        else -> null
    }

    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onItemClick),
        colors = CardDefaults.cardColors(
            containerColor = if (accountGroup.isLocked) 
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f) 
            else 
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Account logo from imageUrl or initials as fallback
                AccountAvatar(
                    issuer = accountGroup.displayIssuer,
                    accountName = accountGroup.displayAccountName,
                    imageUrl = imageUrl,
                    size = 48.dp
                )

                Spacer(modifier = Modifier.width(16.dp))

                // Issuer and account name
                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    Text(
                        text = accountGroup.displayIssuer,
                        style = MaterialTheme.typography.titleMedium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    Text(
                        text = accountGroup.displayAccountName,
                        style = MaterialTheme.typography.bodyMedium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )

                    // Authentication type indicators
                    Row(
                        modifier = Modifier.padding(top = 4.dp),
                        horizontalArrangement = Arrangement.Start,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        if (hasOathCredentials) {
                            Box(
                                modifier = Modifier
                                    .background(
                                        color = MaterialTheme.colorScheme.primaryContainer,
                                        shape = RoundedCornerShape(4.dp)
                                    )
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = stringResource(id = R.string.account_group_item_oath),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                            Spacer(modifier = Modifier.width(4.dp))
                        }

                        if (hasPushCredentials) {
                            Box(
                                modifier = Modifier
                                    .background(
                                        color = MaterialTheme.colorScheme.secondaryContainer,
                                        shape = RoundedCornerShape(4.dp)
                                    )
                                    .padding(horizontal = 6.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = stringResource(id = R.string.account_group_item_push),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSecondaryContainer
                                )
                            }
                        }
                    }
                }

                // OATH code display (only if there are OATH credentials and account is not locked)
                if (hasOathCredentials && !accountGroup.isLocked) {
                    Box(
                        modifier = Modifier
                            .padding(start = 4.dp)
                            .wrapContentWidth()
                    ) {
                        firstOathCode?.let { info ->
                            val otpCodeLabel = stringResource(id = R.string.account_group_item_otp_code_label)
                            Column(
                                modifier = Modifier.offset(x = 12.dp),
                                horizontalAlignment = Alignment.End
                            ) {
                                val displayText = if (tapToRevealEnabled && !isRevealed) {
                                    stringResource(id = R.string.account_group_item_otp_placeholder)
                                } else {
                                    info.code
                                }
                                
                                Text(
                                    text = displayText,
                                    style = MaterialTheme.typography.headlineSmall,
                                    modifier = Modifier.clickable {
                                        when {
                                            tapToRevealEnabled && !isRevealed -> {
                                                // Reveal the code
                                                isRevealed = true
                                            }
                                            copyOtpEnabled && isRevealed -> {
                                                // Copy the code to clipboard
                                                onCopyToClipboard(info.code, otpCodeLabel)
                                            }
                                            !tapToRevealEnabled && copyOtpEnabled -> {
                                                // Copy the code to clipboard
                                                onCopyToClipboard(info.code, otpCodeLabel)
                                            }
                                            else -> {
                                                // Default behavior - open detail screen
                                                onItemClick()
                                            }
                                        }
                                    }
                                )

                                if (firstOathCredential.oathType == OathType.TOTP) {
                                    // Progress indicator for TOTP
                                    LinearProgressIndicator(
                                        progress = { 1f - progress },  // Reverse progress (countdown)
                                        modifier = Modifier
                                            .width(80.dp)
                                            .padding(top = 4.dp),
                                        color = MaterialTheme.colorScheme.primary
                                    )
                                }
                            }
                        } ?: run {
                            // If no code is generated yet, show a code placeholder button
                            TextButton(onClick = {
                                if (firstOathCredential != null) {
                                    onRefreshCode(firstOathCredential.id)
                                }
                            }) {
                                Text(stringResource(id = R.string.account_group_item_otp_placeholder))
                            }
                        }
                    }

                    // Refresh or timer icon for OATH codes
                    Column(
                        modifier = Modifier
                            .wrapContentWidth()
                            .offset(x = 12.dp),
                        horizontalAlignment = Alignment.End
                    ) {
                        if (firstOathCredential?.oathType == OathType.TOTP) {
                            IconButton(onClick = {}) {
                                Icon(Icons.Default.Timelapse, contentDescription = null)
                            }
                        } else if (firstOathCredential != null) {
                            IconButton(onClick = { onRefreshCode(firstOathCredential.id) }) {
                                Icon(Icons.Default.Refresh, contentDescription = null)
                            }
                        }
                    }
                }
            }
            
            // Show lock message if account is locked
            if (accountGroup.isLocked) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(
                            color = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.3f),
                            shape = RoundedCornerShape(4.dp)
                        )
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Lock,
                        contentDescription = stringResource(id = R.string.account_locked_indicator),
                        tint = MaterialTheme.colorScheme.error,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    val lockMessage = getLockMessage(accountGroup.lockingPolicy)
                    Text(
                        text = lockMessage,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error
                    )
                }
            }
        }
    }
}