/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AccountGroup

/**
 * Composable that displays an editable account item with avatar, issuer, account name,
 * credential counts, and buttons for edit, delete, and reorder (move up/down).
 *
 * @param accountGroup The AccountGroup to display.
 * @param onDeleteClick Callback when the delete button is clicked.
 * @param onEditClick Callback when the edit button is clicked.
 * @param onMoveUp Callback when the move up button is clicked.
 * @param onMoveDown Callback when the move down button is clicked.
 * @param canMoveUp Whether the account can be moved up (not the first item).
 * @param canMoveDown Whether the account can be moved down (not the last item).
 */
@Composable
fun EditableAccountItem(
    accountGroup: AccountGroup,
    onDeleteClick: () -> Unit,
    onEditClick: () -> Unit,
    onMoveUp: () -> Unit,
    onMoveDown: () -> Unit,
    canMoveUp: Boolean,
    canMoveDown: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = if (accountGroup.isLocked) 
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f) 
            else 
                MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Reorder controls
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier.padding(end = 12.dp)
            ) {
                IconButton(
                    onClick = onMoveUp,
                    enabled = canMoveUp,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.KeyboardArrowUp,
                        contentDescription = "Move Up",
                        tint = if (canMoveUp) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                    )
                }
                IconButton(
                    onClick = onMoveDown,
                    enabled = canMoveDown,
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.KeyboardArrowDown,
                        contentDescription = "Move Down",
                        tint = if (canMoveDown) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
                    )
                }
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Account avatar
            val imageUrl = accountGroup.oathCredentials.firstOrNull()?.imageURL
                ?: accountGroup.pushCredentials.firstOrNull()?.imageURL

            AccountAvatar(
                issuer = accountGroup.displayIssuer,
                accountName = accountGroup.displayAccountName,
                imageUrl = imageUrl,
                size = 48.dp
            )

            Spacer(modifier = Modifier.width(16.dp))

            // Account info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = accountGroup.displayIssuer,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    text = accountGroup.displayAccountName,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )

                // Show credential counts
                val oathCount = accountGroup.oathCredentials.size
                val pushCount = accountGroup.pushCredentials.size
                val credentialInfo = buildString {
                    if (oathCount > 0) append("$oathCount OATH")
                    if (oathCount > 0 && pushCount > 0) append(", ")
                    if (pushCount > 0) append("$pushCount Push")
                }

                Text(
                    text = credentialInfo,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                
                // Show lock indicator if account is locked
                if (accountGroup.isLocked) {
                    Row(
                        modifier = Modifier.padding(top = 4.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Lock,
                            contentDescription = stringResource(id = R.string.account_locked_indicator),
                            tint = MaterialTheme.colorScheme.error,
                            modifier = Modifier.size(14.dp)
                        )
                        Spacer(modifier = Modifier.width(4.dp))
                        Text(
                            text = stringResource(id = R.string.account_locked_indicator),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }

            // Edit button - disabled for locked accounts
            IconButton(
                onClick = onEditClick,
                enabled = !accountGroup.isLocked
            ) {
                Icon(
                    imageVector = Icons.Default.Edit,
                    contentDescription = "Edit Account",
                    tint = if (accountGroup.isLocked) 
                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f) 
                    else 
                        MaterialTheme.colorScheme.primary
                )
            }

            // Delete button - disabled for locked accounts
            IconButton(
                onClick = onDeleteClick,
                enabled = !accountGroup.isLocked
            ) {
                Icon(
                    imageVector = Icons.Default.Delete,
                    contentDescription = "Delete Account",
                    tint = if (accountGroup.isLocked) 
                        MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f) 
                    else 
                        MaterialTheme.colorScheme.error
                )
            }
        }
    }
}