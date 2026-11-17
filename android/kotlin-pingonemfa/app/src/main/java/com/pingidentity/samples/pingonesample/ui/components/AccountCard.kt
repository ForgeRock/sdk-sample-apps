/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.pingidentity.pingonemfa.commons.PingOneMfaAccount
import com.pingidentity.samples.pingonesample.R

/**
 * A card representing a single registered PingOne MFA account.
 *
 * Displays the following information:
 * - **Title** — first + last name concatenated; falls back to [PingOneMfaAccount.username]
 *   when both [PingOneMfaAccount.name] and [PingOneMfaAccount.family] are blank or null.
 * - **Name** — the raw [PingOneMfaAccount.name] (given name) when present.
 * - **Family** — the raw [PingOneMfaAccount.family] (family name) when present.
 * - **Region** — the region key returned by the PingOne server (e.g. `"NA"`, `"EU"`).
 * - **ID** — the PingOne user ID.
 *
 * OTP code display has been moved to the dedicated [OtpBox] component shown above the list.
 *
 * @param account The [PingOneMfaAccount] to display.
 * @param modifier Optional [Modifier] applied to the card container.
 */
@Composable
fun AccountCard(
    account: PingOneMfaAccount,
    modifier: Modifier = Modifier,
) {
    // Build the display name: "First Last", "First", "Last", or fall back to username
    val displayName = listOfNotNull(
        account.name?.takeIf { it.isNotBlank() },
        account.family?.takeIf { it.isNotBlank() },
    ).joinToString(" ").ifBlank { account.username }

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
        ),
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            AccountAvatar(
                seed = displayName,
                size = 48.dp,
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                // Name line
                Text(
                    text = displayName,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(modifier = Modifier.height(2.dp))
                // Name (given name) line — shown only when present
                account.name?.takeIf { it.isNotBlank() }?.let { given ->
                    Text(
                        text = stringResource(R.string.account_card_name_label, given),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                // Family (family name) line — shown only when present
                account.family?.takeIf { it.isNotBlank() }?.let { family ->
                    Text(
                        text = stringResource(R.string.account_card_family_label, family),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                // Region line
                Text(
                    text = stringResource(R.string.account_card_region_label, account.region),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                // ID line
                Text(
                    text = stringResource(R.string.account_card_id_label, account.id),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
}
