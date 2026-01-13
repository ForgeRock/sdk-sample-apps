/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


package com.pingidentity.samples.journeyapp.journey.callback

import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import com.pingidentity.idp.journey.SelectIdpCallback
import com.pingidentity.samples.journeyapp.R


private const val LOCAL_AUTHENTICATION = "localAuthentication"

@Composable
fun SelectIdpCallback(callback: SelectIdpCallback, onSelected: () -> Unit) {

    Column(
        modifier = Modifier
            .fillMaxWidth(),
    ) {
        callback.providers.forEach {

            Row(
                modifier = Modifier
                    .padding(4.dp)
                    .fillMaxWidth(),
                horizontalArrangement = Arrangement.Center
            ) {
                var id = -1
                if (it.provider.lowercase().contains("facebook")) {
                    id = R.drawable.facebook
                }
                if (it.provider.lowercase().contains("google")) {
                    id = R.drawable.google
                }
                if (it.provider.lowercase().contains("apple")) {
                    id = R.drawable.apple
                }

                if (it.provider == LOCAL_AUTHENTICATION) {
                    callback.value = LOCAL_AUTHENTICATION
                }

                if (id > 0) {
                    Image(painter = painterResource(id = id),
                        contentDescription = null,
                        modifier = Modifier
                            .width(200.dp)
                            .wrapContentWidth(Alignment.CenterHorizontally)
                            .clickable {
                                callback.value = it.provider
                                onSelected()
                            }
                    )
                }
            }
        }
    }

}