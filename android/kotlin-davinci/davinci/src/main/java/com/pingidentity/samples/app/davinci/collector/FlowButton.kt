/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.FlowCollector

@Composable
fun FlowButton(
    field: FlowCollector,
    onNext: () -> Unit,
) {
    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        field.value = ""
        TextButton(
            modifier =
            Modifier
                .fillMaxWidth()
                .wrapContentWidth(Alignment.CenterHorizontally),
            onClick = {
                field.value = "action"
                onNext()
            },
        ) {
            androidx.compose.material3.Text(field.label)
        }
    }
}