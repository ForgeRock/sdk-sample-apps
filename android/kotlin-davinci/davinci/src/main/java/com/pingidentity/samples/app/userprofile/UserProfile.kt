/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.userprofile

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Composable
fun UserProfile(userProfileViewModel: UserProfileViewModel) {
    val state by userProfileViewModel.state.collectAsState()

    LaunchedEffect(true) {
        // Not relaunch when recomposition
        userProfileViewModel.userinfo()
    }

    Column(
        modifier =
            Modifier.padding(8.dp)
                .fillMaxWidth(),
    ) {
        Card(
            elevation =
                CardDefaults.cardElevation(
                    defaultElevation = 10.dp,
                ),
            modifier =
                Modifier
                    .fillMaxWidth(),
            border = BorderStroke(2.dp, Color.Black),
            shape = MaterialTheme.shapes.medium,
        ) {
            Text(
                modifier = Modifier.padding(4.dp),
                text =
                    state.user?.let {
                        prettyJson.encodeToString(it)
                    } ?: state.error?.toString() ?: "",
            )
        }

        Button(
            modifier = Modifier.align(Alignment.End),
            onClick = { userProfileViewModel.userinfo() },
        ) {
            Text(text = "Show UserInfo")
        }
    }
}

@OptIn(ExperimentalSerializationApi::class)
val prettyJson =
    Json { // this returns the JsonBuilder
        prettyPrint = true
        prettyPrintIndent = " "
    }
