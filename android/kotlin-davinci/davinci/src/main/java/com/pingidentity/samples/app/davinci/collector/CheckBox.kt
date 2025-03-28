/*
 * Copyright (c) 2024 - 2025 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.MultiSelectCollector

@Composable
fun CheckBox(field: MultiSelectCollector, onNodeUpdated: () -> Unit) {
    val selectedOptions= remember { mutableStateMapOf<String, Boolean>() }

    LaunchedEffect(field) {
        field.options.forEach { item ->
            selectedOptions[item.value] = field.value.contains(item.value)
        }
    }

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
            val isChecked = selectedOptions[option.value]
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Checkbox(
                    checked = isChecked == true,
                    onCheckedChange = { checked ->
                        selectedOptions[option.value] = checked
                        if (checked) {
                            field.value.add(option.value)
                        } else {
                            field.value.remove(option.value)
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
