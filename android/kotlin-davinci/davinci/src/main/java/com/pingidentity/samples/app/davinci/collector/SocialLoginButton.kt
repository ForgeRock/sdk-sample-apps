/*
 * Copyright (c) 2024 - 2025 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import android.util.Log
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.material3.Button
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.pingidentity.browser.BrowserLauncher
import com.pingidentity.idp.davinci.IdpCollector
import com.pingidentity.samples.app.R
import kotlinx.coroutines.launch

@Composable
fun SocialLoginButton(
    idpCollector: IdpCollector,
    onStart: () -> Unit,
    onNext: () -> Unit,
) {
    val coroutineScope = rememberCoroutineScope()

    Row(
        modifier =
        Modifier
            .padding(4.dp)
            .fillMaxWidth(),
    ) {
        var id = -1
        when (idpCollector.idpType) {
            "APPLE" -> id = R.drawable.apple
            "GOOGLE" -> id = R.drawable.google
            "FACEBOOK" -> id = R.drawable.facebook
        }
        Spacer(modifier = Modifier.weight(1f, true))
        //When image not found, display a button with the label
        if (id == -1) {
            Button(
                modifier =
                Modifier
                    .fillMaxWidth()
                    .wrapContentWidth(Alignment.CenterHorizontally),
                onClick = {
                    coroutineScope.launch {
                        BrowserLauncher.customTabsCustomizer = {
                            setShowTitle(false)
                            setUrlBarHidingEnabled(true)
                        }
                        val result = idpCollector.authorize()
                        result.onSuccess {
                            onNext()
                        }
                        result.onFailure {
                            Log.e(
                                "SocialLoginButton",
                                "Failed to authorize",
                                it
                            )
                            onStart() //restart the flow, cause the url may expired
                        }
                    }
                },
            ) {
                androidx.compose.material3.Text(idpCollector.label)
            }
        } else {
            Image(painter = painterResource(id = id),
                contentDescription = null,
                modifier = Modifier
                    .width(200.dp)
                    .wrapContentWidth(Alignment.CenterHorizontally)
                    .clickable {
                        coroutineScope.launch {
                            BrowserLauncher.customTabsCustomizer = {
                                setShowTitle(false)
                                setUrlBarHidingEnabled(true)
                            }
                            val result = idpCollector.authorize()
                            result.onSuccess { onNext() }
                            result.onFailure {
                                Log.e(
                                    "SocialLoginButton",
                                    "Failed to authorize",
                                    it
                                )
                                onStart() //restart the flow, cause the url may expired
                            }
                        }
                    }
            )
        }
        Spacer(modifier = Modifier.weight(1f, true))
    }
}