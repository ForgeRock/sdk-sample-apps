/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.journey.callback.ChoiceCallback

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChoiceCallback(callback: ChoiceCallback,  onNodeUpdated: () -> Unit) {
    var expanded by remember(callback) { mutableStateOf(false) }
    var selectedItem by remember(callback) {
        mutableStateOf(callback.choices[callback.defaultChoice])
    }

    Column(
        modifier = Modifier
            .padding(8.dp)
            .fillMaxWidth()
    ) {
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = {
                expanded = !expanded
            }
        ) {

            // text field
            TextField(
                modifier = Modifier.menuAnchor(MenuAnchorType.PrimaryNotEditable, true),
                value = selectedItem,
                onValueChange = {},
                readOnly = true,
                label = { Text(text = callback.prompt) },
                trailingIcon = {
                    ExposedDropdownMenuDefaults.TrailingIcon(
                        expanded = expanded
                    )
                },
                colors = ExposedDropdownMenuDefaults.textFieldColors()
            )

            // menu
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                callback.choices.forEachIndexed { index, selectedOption ->
                    // menu item
                    DropdownMenuItem(text = {
                        Text(text = selectedOption)
                    }, onClick = {
                        selectedItem = selectedOption
                        expanded = false
                        callback.selectedIndex = index
                        onNodeUpdated()
                    })
                }
            }
        }
    }
}
