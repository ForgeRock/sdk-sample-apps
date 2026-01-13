/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.journeyapp.journey.callback

import android.util.Log
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.wrapContentSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.pingidentity.fido.journey.FidoAuthenticationCallback
import kotlinx.coroutines.launch

@Composable
fun FidoAuthentication(
    callback: FidoAuthenticationCallback,
    onNext: () -> Unit,
) {
    val currentOnCompleted by rememberUpdatedState(onNext)

    Box(
        modifier = Modifier
            .fillMaxSize()
            .wrapContentSize(Alignment.Center)
    ) {
        CircularProgressIndicator()
        LaunchedEffect(true) {
            launch {
                callback.authenticate().onSuccess {
                    currentOnCompleted()
                }.onFailure {
                    Log.e(
                        "Fido2Authentication",
                        "Failed to Authenticate",
                        it
                    )
                    currentOnCompleted()
                }
            }
        }
    }
}