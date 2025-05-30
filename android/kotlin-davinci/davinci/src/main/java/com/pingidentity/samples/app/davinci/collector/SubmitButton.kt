/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.Button
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.SubmitCollector

/**
 * The submit button.
 *
 * @param field The submit collector.
 * @param onNext The callback to be called when the next node is triggered.
 */
@Composable
fun SubmitButton(
    field: SubmitCollector,
    onNext: () -> Unit,
) {
    field.value = ""
    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        Button(
            modifier =
            Modifier
                .fillMaxWidth()
                .wrapContentWidth(Alignment.CenterHorizontally),
            onClick = {
                field.value = "submit"
                onNext()
            },
        ) {
            androidx.compose.material3.Text(field.label)
        }
    }
}