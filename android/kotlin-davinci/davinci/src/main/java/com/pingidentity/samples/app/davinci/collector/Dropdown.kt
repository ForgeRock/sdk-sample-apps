/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults.TrailingIcon
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.SingleSelectCollector

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun Dropdown(field: SingleSelectCollector, onNodeUpdated: () -> Unit) {
    val options = listOf("") + field.options.map { it.value }
    var expanded by remember { mutableStateOf(false) }
    var selectedOption by remember { mutableStateOf(field.value) }

    var isValid by remember {
        mutableStateOf(true)
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
                value = selectedOption,
                onValueChange = {
                    selectedOption = it
                },
                readOnly = true, // Make it readonly so the dropdown acts like a spinner
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
                    DropdownMenuItem(
                        text = { androidx.compose.material3.Text(text = option) },
                        onClick = {
                            selectedOption = option
                            expanded = false // Close the dropdown on selection
                            field.value = option
                            isValid = field.validate().isEmpty()
                            onNodeUpdated()
                        }
                    )
                }
            }
        }
    }
}
