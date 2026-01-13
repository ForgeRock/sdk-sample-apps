/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.pingidentity.protect.journey.PingOneProtectInitializeCallback
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun PingOneProtectInitialize(
    field: PingOneProtectInitializeCallback,
    onNext: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var isLoading by remember(field) { mutableStateOf(true) }

    // Execute the loading task when the composable is first composed
    LaunchedEffect(key1 = field) {
        scope.launch {
            try {
                val startTime = System.currentTimeMillis()
                field.start()
                val taskDuration = System.currentTimeMillis() - startTime

                // If task completed too quickly, delay to meet minimum display time
                val remainingTime = 2000 - taskDuration
                if (remainingTime > 0) {
                    delay(remainingTime)
                }
                isLoading = false
                onNext()
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