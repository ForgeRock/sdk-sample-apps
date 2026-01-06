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
import com.pingidentity.recaptcha.enterprise.ReCaptchaEnterpriseCallback
import kotlinx.coroutines.launch

/**
 * Composable function for handling ReCaptcha Enterprise verification in the Journey UI.
 *
 * This Composable automatically initiates ReCaptcha Enterprise verification when displayed
 * and shows a loading indicator during the verification process. The verification uses
 * the default ReCaptcha client provider and handles both success and failure scenarios.
 *
 * The UI behavior:
 * - Displays a loading spinner with progress text during verification
 * - Automatically proceeds to the next step on successful verification
 * - For demo purposes, also proceeds on failure (in production, you may want to handle errors differently)
 *
 * @param reCaptchaEnterpriseCallback The ReCaptcha Enterprise callback instance from the Journey
 * @param onNext Callback function to invoke when verification completes (success or failure)
 *
 * Example usage:
 * ```kotlin
 * ReCaptchaEnterpriseCallback(
 *     reCaptchaEnterpriseCallback = callback,
 *     onNext = { viewModel.proceedToNextStep() }
 * )
 * ```
 */
@Composable
fun ReCaptchaEnterpriseCallback(
    reCaptchaEnterpriseCallback: ReCaptchaEnterpriseCallback,
    onNext: () -> Unit,
) {
    val scope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(true) }

    LaunchedEffect(key1 = true) {
        scope.launch {
            reCaptchaEnterpriseCallback.verify {
                // Optionally customize the configuration here
            }.onSuccess { result ->
                println("ReCaptcha Token Result: $result")
                isLoading = false
                onNext()
            }.onFailure { error ->
                println("ReCaptcha Verification Failed: ${error.message}")
                isLoading = false
                onNext() // Proceeding to next step even on failure for demo purposes
            }
        }
    }

    // The UI will always show the loading indicator until collection is complete.
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
                CircularProgressIndicator(modifier = Modifier.size(48.dp))
                Spacer(modifier = Modifier.height(16.dp))
                Text(text = "ReCaptcha verification in progress...")
            }
        }
    }
}