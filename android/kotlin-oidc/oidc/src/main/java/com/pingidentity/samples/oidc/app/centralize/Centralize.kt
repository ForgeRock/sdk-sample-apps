/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.centralize

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

@Composable
fun Centralize(
    centralizeLoginViewModel: CentralizeLoginViewModel,
    onSuccess: (() -> Unit) = {},
) {
    val scroll = rememberScrollState(0)
    LaunchedEffect(true) {
        // Not relaunch when recomposition
        centralizeLoginViewModel.login()
    }

    val state by centralizeLoginViewModel.state.collectAsState()

    Column(
        modifier =
            Modifier
                .fillMaxWidth(),
    ) {
        Card(
            elevation =
                CardDefaults.cardElevation(
                    defaultElevation = 10.dp,
                ),
            modifier =
                Modifier
                    .weight(1f)
                    .fillMaxHeight()
                    .fillMaxWidth()
                    .padding(8.dp),
            border = BorderStroke(2.dp, Color.Black),
            shape = MaterialTheme.shapes.medium,
        ) {
            state.user?.let {
                LaunchedEffect(true) {
                    onSuccess()
                }
            }
            Text(
                modifier =
                    Modifier
                        .padding(4.dp)
                        .verticalScroll(scroll),
                text =
                    state.error?.toString() ?: "",
            )
        }
    }
}
