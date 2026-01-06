/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.journey.callback.ConfirmationCallback

@Composable
fun ConfirmationCallback(callback: ConfirmationCallback, onSelected: () -> Unit) {

    Row(modifier = Modifier
        .padding(8.dp)
        .fillMaxWidth(),
        horizontalArrangement = Arrangement.End) {

        callback.options.forEachIndexed { index, item ->
            Button(
                modifier = Modifier.padding(4.dp),
                onClick = { callback.selectedIndex = index; onSelected() }) {
                Text(item)
            }
        }
    }

}