/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.TextCollector

@Composable
fun Text(
    field: TextCollector,
    onNodeUpdated: () -> Unit,
) {
    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        // var text by rememberSaveable { mutableStateOf("") }

        Spacer(modifier = Modifier.weight(1f, true))

        OutlinedTextField(
            modifier = Modifier.wrapContentWidth(Alignment.CenterHorizontally),
            value = field.value,
            onValueChange = { value ->
                // text = value
                field.value = value
                onNodeUpdated()
            },
            label = { androidx.compose.material3.Text(field.label) },
        )
        Spacer(modifier = Modifier.weight(1f, true))
    }
}