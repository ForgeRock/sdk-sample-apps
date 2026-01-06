/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.journey.callback.ConsentMappingCallback

@Composable
fun ConsentMappingCallback(callback: ConsentMappingCallback, onNodeUpdated: () -> Unit) {

    var input by remember(callback) {
        mutableStateOf(false)
    }

    Column (modifier = Modifier
        .padding(16.dp)
        .fillMaxWidth()) {
        Text(text = "Name: ${callback.name}",
            style = MaterialTheme.typography.titleMedium
        )
        Spacer(Modifier.width(8.dp))
        Text(text = "DisplayName: ${callback.displayName}",
            style = MaterialTheme.typography.titleMedium
        )
        Spacer(Modifier.width(8.dp))
        Text(text = "Icon: ${callback.icon}",
            style = MaterialTheme.typography.titleSmall
        )
        Spacer(Modifier.width(8.dp))
        Text(text = "AccessLevel: ${callback.accessLevel}",
            style = MaterialTheme.typography.titleSmall
        )
        Spacer(Modifier.width(8.dp))
        Text(text = "IsRequired: ${callback.isRequired}",
            style = MaterialTheme.typography.titleSmall
        )
        callback.fields.forEach {
            Spacer(Modifier.width(8.dp))
            Text(text = "field: $it",
                style = MaterialTheme.typography.titleSmall
            )
        }
        Spacer(Modifier.width(8.dp))
        Text(text = "Message: ${callback.message}",
            style = MaterialTheme.typography.titleSmall
        )

        Spacer(Modifier.width(8.dp))
        Switch(
            checked = input,
            onCheckedChange = {
                input = it
                callback.accepted = it
                onNodeUpdated()
            }
        )
    }

}