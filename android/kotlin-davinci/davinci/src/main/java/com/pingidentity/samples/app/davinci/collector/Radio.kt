/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.RadioButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.SingleSelectCollector

@Composable
fun Radio(field: SingleSelectCollector, onNodeUpdated: () -> Unit) {
    var selectedOption by remember { mutableStateOf(field.value) }

    var isValid by remember {
        mutableStateOf(true)
    }

    OutlinedCard (
        modifier = Modifier
            .padding(8.dp)
            .fillMaxWidth()
    ) {
        androidx.compose.material3.Text(
            modifier = Modifier.padding(8.dp),
            text =if (field.required) "${field.label}*" else field.label,
            style = MaterialTheme.typography.titleSmall,
        )
        if (!isValid) {
            ErrorMessage(field.validate())
        }
        field.options.forEach { option ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                RadioButton(
                    selected = selectedOption == option.value,
                    onClick = {
                        if (selectedOption == option.value) {
                            // Reset to unselected state
                            selectedOption = ""
                            field.value = ""
                        } else {
                            // Select the option
                            selectedOption = option.value
                            field.value = option.value
                        }
                        isValid = field.validate().isEmpty()
                        onNodeUpdated()
                    }
                )
                androidx.compose.material3.Text(text = option.label)
            }
        }
    }
}
