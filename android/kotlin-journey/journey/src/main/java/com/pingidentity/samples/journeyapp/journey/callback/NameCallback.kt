/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

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
import com.pingidentity.journey.callback.NameCallback

@Composable
fun NameCallback(
    field: NameCallback,
    onNodeUpdated: () -> Unit,
) {

    var text by remember(field) { mutableStateOf(field.name) }

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
            value = text,
            onValueChange = { value ->
                text = value
                field.name = value
                onNodeUpdated()
            },
            label = { androidx.compose.material3.Text(field.prompt) },
        )
        Spacer(modifier = Modifier.weight(1f, true))
    }
}