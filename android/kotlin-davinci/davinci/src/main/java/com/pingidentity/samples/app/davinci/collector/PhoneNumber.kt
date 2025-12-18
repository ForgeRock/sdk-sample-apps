/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.ExposedDropdownMenuDefaults.TrailingIcon
import androidx.compose.material3.MenuAnchorType
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.PhoneNumberCollector

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PhoneNumber(field: PhoneNumberCollector, onNodeUpdated: () -> Unit) {
    var expanded by remember(field) { mutableStateOf(false) }
    var selectedCountryCode by remember(field) {
        val codeToUse = field.countryCode.ifEmpty { field.defaultCountryCode }
        mutableStateOf(
            countryCodes.firstOrNull { it.countryCode == codeToUse }
                ?: countryCodes.first()
        )
    }
    var phone by remember(field) { mutableStateOf(field.phoneNumber) }

    var isValid by remember(field) {
        mutableStateOf(true)
    }

    LaunchedEffect(true) {
        field.countryCode = selectedCountryCode.countryCode
        field.phoneNumber = field.phoneNumber
    }

    Column(
        modifier = Modifier
            .padding(8.dp)
            .fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {

            // Country Code Dropdown
            ExposedDropdownMenuBox(
                expanded = expanded,
                onExpandedChange = { expanded = !expanded },
                modifier = Modifier.width(120.dp)
            ) {
                // Dropdown Trigger
                OutlinedTextField(
                    value = selectedCountryCode.countryCodeNumber,
                    onValueChange = {},
                    readOnly = true,
                    label = { androidx.compose.material3.Text("Country") },
                    trailingIcon = {
                        TrailingIcon(expanded = expanded)
                    },
                    colors = ExposedDropdownMenuDefaults.textFieldColors(),
                    modifier = Modifier
                        .menuAnchor(MenuAnchorType.PrimaryNotEditable)
                        .fillMaxWidth()
                )

                // Dropdown Menu
                ExposedDropdownMenu(
                    expanded = expanded,
                    onDismissRequest = { expanded = false }
                ) {
                    countryCodes.forEach { countryCode ->
                        DropdownMenuItem(
                            text = { androidx.compose.material3.Text("${countryCode.name} +${countryCode.countryCodeNumber}") },
                            onClick = {
                                selectedCountryCode = countryCode
                                expanded = false
                                field.countryCode = countryCode.countryCode
                                onNodeUpdated()
                            },
                            contentPadding = ExposedDropdownMenuDefaults.ItemContentPadding
                        )
                    }
                }
            }
            // Phone Number Input
            OutlinedTextField(
                value = phone,
                onValueChange = { value ->
                    val phoneNumber = value.take(10).filter { it.isDigit() }
                    phone = phoneNumber
                    field.phoneNumber = phoneNumber
                },
                label = { androidx.compose.material3.Text(field.label) },
                singleLine = true,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                modifier = Modifier.weight(1f)
            )
        }
    }

}

data class Country(
    val countryCode: String,
    val name: String,
    val countryCodeNumber: String
)

val countryCodes = listOf(
    Country("US", "United States", "1"),
    Country("CA", "Canada", "1"),
    Country("GB", "United Kingdom", "44"),
    Country("AU", "Australia", "61"),
    Country("DE", "Germany", "49"),
    Country("FR", "France", "33"),
    Country("JP", "Japan", "81"),
    Country("CN", "China", "86"),
    Country("IN", "India", "91"),
    Country("BR", "Brazil", "55"),
    Country("RU", "Russia", "7"),
    Country("IT", "Italy", "39"),
    Country("KR", "South Korea", "82"),
    Country("MX", "Mexico", "52"),
    Country("ES", "Spain", "34"),
    Country("ZA", "South Africa", "27"),
    Country("HK", "Hong Kong", "852"),
    // Add more countries as needed
)
