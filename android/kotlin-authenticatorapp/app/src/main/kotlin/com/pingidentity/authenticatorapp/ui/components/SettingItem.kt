/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

/**
 * A reusable setting item component that displays an icon, title, description,
 * and either a toggle switch or a navigation arrow.
 *
 * @param icon The icon to display on the left side of the setting item.
 * @param title The title text of the setting item.
 * @param description The description text of the setting item.
 * @param checked The current state of the toggle switch (if applicable).
 * @param hasNavigation Whether to show a navigation arrow instead of a toggle switch.
 * @param onToggle Optional callback invoked when the toggle switch is changed.
 * @param onNavigate Optional callback invoked when the item is clicked for navigation.
 * @param modifier Optional modifier to apply to the entire setting item.
 */
@Composable
fun SettingItem(
    icon: ImageVector,
    title: String,
    description: String,
    checked: Boolean = false,
    hasNavigation: Boolean = false,
    onToggle: ((Boolean) -> Unit)? = null,
    onNavigate: (() -> Unit)? = null,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clickable(enabled = hasNavigation && onNavigate != null) {
                    if (hasNavigation && onNavigate != null) {
                        onNavigate()
                    }
                }
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Icon
            Icon(
                imageVector = icon,
                contentDescription = null,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            // Title and description
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.bodyLarge
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = description,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            // Toggle or navigation arrow
            if (hasNavigation && onNavigate != null) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = "Navigate",
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            } else if (onToggle != null) {
                Spacer(modifier = Modifier.width(4.dp))
                Switch(
                    checked = checked,
                    onCheckedChange = onToggle
                )
            }
        }
    }
}
