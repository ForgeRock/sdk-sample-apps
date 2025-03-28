/*
 * Copyright (c) 2025 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Checkbox
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults.TrailingIcon
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.MultiSelectCollector

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ComboBox(field: MultiSelectCollector, onNodeUpdated: () -> Unit) {
    val options = field.options.map { it.value }
    var expanded by remember { mutableStateOf(false) }
    val selectedOptions = remember { mutableStateListOf<String>() }

    var isValid by remember {
        mutableStateOf(true)
    }

    LaunchedEffect(field) {
        selectedOptions.clear()
        field.options.forEach { item ->
            if (field.value.contains(item.value)) {
                selectedOptions.add(item.value)
            }
        }
    }

    Column(
        modifier = Modifier
            .padding(8.dp)
            .fillMaxWidth()
    ) {
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = !expanded }
        ) {
            OutlinedTextField(
                value = if (selectedOptions.isEmpty()) "" else selectedOptions.joinToString(),
                onValueChange = {

                },
                readOnly = true,
                label = { androidx.compose.material3.Text(if (field.required) "${field.label}*" else field.label) },
                trailingIcon = {
                    TrailingIcon(expanded = expanded)
                },
                isError = !isValid,
                supportingText = if (!isValid) {
                    @Composable {
                        ErrorMessage(field.validate())
                    }
                } else null,
                modifier = Modifier
                    .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                    .fillMaxWidth()
            )

            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                options.forEach { option ->
                    val isSelected = option in selectedOptions
                    DropdownMenuItem(
                        text = {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Checkbox(
                                    checked = isSelected,
                                    onCheckedChange = null // Handle clicks on the row instead
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                androidx.compose.material3.Text(text = option)
                            }
                        },
                        onClick = {
                            if (isSelected) {
                                selectedOptions.remove(option)
                                field.value.remove(option)
                            } else {
                                selectedOptions.add(option)
                                field.value.add(option)
                            }
                            onNodeUpdated()
                            isValid = field.validate().isEmpty()
                        }
                    )
                }
            }
        }
    }
}
