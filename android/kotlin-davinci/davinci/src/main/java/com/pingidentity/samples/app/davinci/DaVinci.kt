/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci

import android.util.Log
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Error
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pingidentity.davinci.module.continueNode
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.SuccessNode
import com.pingidentity.samples.app.Alert
import com.pingidentity.samples.app.R
import com.pingidentity.samples.app.davinci.collector.ContinueNode

@Composable
fun DaVinci(
    daVinciViewModel: DaVinciViewModel = viewModel<DaVinciViewModel>(),
    onSuccess: (() -> Unit)? = null,
) {
    BackHandler {
        daVinciViewModel.start()
    }

    val state by daVinciViewModel.state.collectAsState()
    val loading by daVinciViewModel.loading.collectAsState()
    val currentOnSuccess by rememberUpdatedState(onSuccess)

    DaVinci(
        state = state,
        loading = loading,
        onNodeUpdated = {
            daVinciViewModel.refresh()
        },
        onNext = {
            daVinciViewModel.next(it)
        },
        onStart = {
            daVinciViewModel.start()
        },
        currentOnSuccess,
    )
}

@Composable
fun DaVinci(
    state: DaVinciState,
    loading: Boolean,
    onNodeUpdated: () -> Unit,
    onNext: (ContinueNode) -> Unit,
    onStart: () -> Unit,
    onSuccess: (() -> Unit)?,
) {
    val scroll = rememberScrollState(0)

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .fillMaxSize().verticalScroll(scroll)
   ) {
        if (loading) {
            CircularProgressIndicator()
        }

        Column(
            modifier =
            Modifier
                .padding(8.dp)
                .fillMaxSize()
        ) {
            Logo(modifier = Modifier)

            when (val node = state.node) {
                is ContinueNode -> {
                    Render(node = node, onNodeUpdated, onStart) {
                        onNext(node)
                    }
                }

                is FailureNode -> {
                    Log.e("DaVinci", node.cause.message, node.cause)
                    Render(node = node)
                }

                is ErrorNode -> {
                    Render(node)
                    // Render the previous node
                    node.continueNode()?.let {
                        Render(node = it, onNodeUpdated, onStart) {
                            onNext(it)
                        }
                    }
                }

                is SuccessNode -> {
                    LaunchedEffect(true) {
                        onSuccess?.let { onSuccess() }
                    }
                }

                else -> {}
            }
        }
    }
}

@Composable
fun Render(node: FailureNode) {
    Row(
        modifier =
        Modifier
            .padding(16.dp)
            .fillMaxWidth(),
    ) {
        Card(
            elevation =
            CardDefaults.cardElevation(
                defaultElevation = 10.dp,
            ),
            modifier =
            Modifier
                .fillMaxWidth()
                .padding(8.dp),
            shape = MaterialTheme.shapes.medium,
        ) {
            Row(
                modifier =
                Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
            ) {
                Icon(Icons.Filled.Error, null)
                Spacer(Modifier.width(8.dp))
                Text(
                    text = "${node.cause}",
                    Modifier
                        .weight(1f),
                    style = MaterialTheme.typography.titleMedium,
                )
            }
        }
    }
}

@Composable
fun Render(node: ErrorNode) {
    var showAlert by remember { mutableStateOf(false) }

    if (showAlert) {
        Alert(node) {
            showAlert = false
        }
    }

    Row(
        modifier =
        Modifier
            .padding(16.dp)
            .fillMaxWidth(),
    ) {
        Card(
            elevation =
            CardDefaults.cardElevation(
                defaultElevation = 10.dp,
            ),
            modifier =
            Modifier
                .fillMaxWidth()
                .padding(8.dp)
                .clickable {
                    showAlert = true
                },
            shape = MaterialTheme.shapes.medium,
        ) {
            Row(
                modifier =
                Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
            ) {
                Icon(Icons.Filled.Error, null)
                Spacer(Modifier.width(8.dp))
                Text(
                    text = node.message,
                    Modifier
                        .weight(1f),
                    style = MaterialTheme.typography.titleMedium,
                )
            }
        }
    }
}

@Composable
fun Render(
    node: ContinueNode,
    onNodeUpdated: () -> Unit,
    onStart: () -> Unit,
    onNext: () -> Unit,
) {
    ContinueNode(node, onNodeUpdated, onStart, onNext)
}

@Composable
private fun Logo(modifier: Modifier) {
    Row(
        modifier =
        Modifier
            .fillMaxWidth()
            .then(modifier),
    ) {
        Spacer(modifier = Modifier.weight(1f, true))
        Icon(
            painterResource(R.drawable.ping_logo),
            contentDescription = null,
            modifier =
            Modifier
                .height(100.dp)
                .padding(8.dp)
                .wrapContentWidth(Alignment.CenterHorizontally)
                .then(modifier),
            tint = Color.Unspecified,
        )
        Spacer(modifier = Modifier.weight(1f, true))
    }
}