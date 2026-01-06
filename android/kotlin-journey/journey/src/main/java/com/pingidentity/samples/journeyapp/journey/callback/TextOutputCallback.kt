/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.journey.callback.TextOutputCallback
import com.pingidentity.journey.callback.TextOutputCallbackMessageType

@Composable
fun TextOutputCallback(callback: TextOutputCallback) {

    Row(modifier = Modifier
        .padding(16.dp)
        .fillMaxWidth()) {
        when (callback.messageType) {
            TextOutputCallbackMessageType.INFORMATION -> Icon(Icons.Filled.Info, null)
            TextOutputCallbackMessageType.WARNING -> Icon(Icons.Filled.Warning, null)
            TextOutputCallbackMessageType.ERROR -> Icon(Icons.Filled.Error, null)
            else -> Icon(Icons.Filled.Settings, null)
        }
        Spacer(Modifier.width(8.dp))
        Text(text = callback.message,
            Modifier
                .weight(1f),
            style = MaterialTheme.typography.titleMedium
        )
    }

}