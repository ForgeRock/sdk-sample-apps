/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.protect.davinci.ProtectCollector
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun Protect(
    field: ProtectCollector,
    onNodeUpdated: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(true) }
    var errorMessage by remember { mutableStateOf<String?>(null) }

    // Execute the loading task when the composable is first composed
    LaunchedEffect(key1 = true) {
        scope.launch {
            try {
                val startTime = System.currentTimeMillis()
                field.collect()
                val taskDuration = System.currentTimeMillis() - startTime

                // If task completed too quickly, delay to meet minimum display time
                val remainingTime = 2000 - taskDuration
                if (remainingTime > 0) {
                    delay(remainingTime)
                }
                isLoading = false
                onNodeUpdated()
            } catch (e: Exception) {
                isLoading = false
            }
        }
    }

    if (isLoading) {
        Box(
            modifier = Modifier.fillMaxSize(),
            contentAlignment = Alignment.Center
        ) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center,
                modifier = Modifier.padding(16.dp)
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(48.dp)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text(text = "Collecting device profile ...")
            }
        }
    }
}