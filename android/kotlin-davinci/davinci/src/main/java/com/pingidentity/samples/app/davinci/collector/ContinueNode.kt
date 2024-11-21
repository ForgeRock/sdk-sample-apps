/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.pingidentity.davinci.collector.FlowCollector
import com.pingidentity.davinci.collector.PasswordCollector
import com.pingidentity.davinci.collector.SubmitCollector
import com.pingidentity.davinci.collector.TextCollector
import com.pingidentity.davinci.module.description
import com.pingidentity.davinci.module.name
import com.pingidentity.davinci.plugin.collectors
import com.pingidentity.orchestrate.ContinueNode

/**
 * The continue node.
 *
 * @param continueNode The continue node to render.
 * @param onNodeUpdated The callback to be called when the current node is updated.
 * @param onNext The callback to be called when the next node is triggered.
 */
@Composable
fun ContinueNode(
    continueNode: ContinueNode,
    onNodeUpdated: () -> Unit,
    onNext: () -> Unit
) {
    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth()
    ) {
        Spacer(Modifier.width(8.dp))
        Text(
            text = continueNode.name,
            Modifier
                .wrapContentWidth(Alignment.CenterHorizontally)
                .weight(1f),
            fontWeight = FontWeight.Bold,
            style = MaterialTheme.typography.titleLarge,
        )
    }
    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        Spacer(Modifier.width(8.dp))
        Text(
            text = continueNode.description,
            Modifier
                .wrapContentWidth(Alignment.CenterHorizontally)
                .weight(1f),
            style = MaterialTheme.typography.titleSmall,
        )
    }

    Column(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        var hasAction = false

        continueNode.collectors.forEach {
            when (it) {
                is FlowCollector -> {
                    hasAction = true
                    FlowButton(it, onNext)
                }

                is PasswordCollector -> {
                    Password(it, onNodeUpdated)
                }
                is SubmitCollector -> {
                    hasAction = true
                    SubmitButton(it, onNext)
                }

                is TextCollector -> Text(it, onNodeUpdated)

            }
        }

        if (!hasAction) {
            Button(
                modifier = Modifier.align(Alignment.End),
                onClick = onNext,
            ) {
                Text("Next")
            }
        }
    }
}

