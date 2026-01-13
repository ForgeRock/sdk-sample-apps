/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.journey.callback.StringAttributeInputCallback

@Composable
fun StringAttributeInputCallback(callback: StringAttributeInputCallback, onNodeUpdated: () -> Unit) {

    var input by remember(callback) {
        mutableStateOf(callback.value)
    }

    Row(modifier = Modifier
        .padding(4.dp)
        .fillMaxWidth()) {
        OutlinedTextField(
            modifier = Modifier,
            value = input,
            onValueChange = { value ->
                input = value
                callback.value = input
                onNodeUpdated()
            },
            isError = callback.failedPolicies.isNotEmpty(),
            supportingText = if (callback.failedPolicies.isNotEmpty()) {
                @Composable {
                    Text(
                        text = callback.error(),
                        style = MaterialTheme.typography.bodySmall
                    )
                }
            } else null,
            label = { Text(callback.prompt) },
        )
    }
}