/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.OutlinedTextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.TextCollector

@Composable
fun Text(
    field: TextCollector,
    onNodeUpdated: () -> Unit,
) {

    var isValid by remember(field) {
        mutableStateOf(true)
    }
    var text by remember(field) { mutableStateOf(field.value) }

    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {

        Spacer(modifier = Modifier.weight(1f, true))

        OutlinedTextField(
            modifier = Modifier.wrapContentWidth(Alignment.CenterHorizontally),
            value = text ,
            onValueChange = { value ->
                text = value
                field.value = value
                isValid = field.validate().isEmpty()
                onNodeUpdated()
            },
            isError = !isValid,
            supportingText = if (!isValid) {
                @Composable {
                    ErrorMessage(field.validate())
                }
            } else null,
            label = {
                androidx.compose.material3.Text(
                text = if (field.required) "${field.label}*" else field.label
            ) }
        )
        Spacer(modifier = Modifier.weight(1f, true))
    }
}