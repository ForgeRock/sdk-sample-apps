/*
 * Copyright (c) 2024 - 2025 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.app.davinci.collector

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.ImageLoader
import coil.compose.rememberAsyncImagePainter
import coil.decode.SvgDecoder
import com.pingidentity.android.ContextProvider
import com.pingidentity.davinci.collector.DeviceRegistrationCollector

@Composable
fun DeviceRegistration(
    field: DeviceRegistrationCollector,
    onNext: () -> Unit,
) {
    var selectedType by remember { mutableStateOf<String?>(null) }

    OutlinedCard (
        modifier = Modifier
            .padding(8.dp)
            .fillMaxWidth()
    ) {
        androidx.compose.material3.Text(
            modifier = Modifier.padding(8.dp),
            text =if (field.required) "${field.label}*" else field.label,
            style = MaterialTheme.typography.titleSmall,
        )
        field.devices.forEach { device ->
            val isSelected = selectedType == device.type
            OutlinedCard(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        field.value = device
                        selectedType = device.type
                        onNext()
                    }
                    .padding(8.dp),
                elevation = CardDefaults.cardElevation(
                    defaultElevation = 1.dp,
                ),
                colors = CardDefaults.outlinedCardColors(
                    containerColor = if (isSelected) MaterialTheme.colorScheme.primary.copy(alpha = 0.1f) else MaterialTheme.colorScheme.surface
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    // Icon from URL
                    Icon(
                        painter = rememberAsyncImagePainter(model = device.iconSrc,
                            imageLoader = ImageLoader.Builder(ContextProvider.context)
                                .components { add(SvgDecoder.Factory()) }
                                .build()
                        ),
                        contentDescription = device.title,
                        modifier = Modifier
                            .size(40.dp)
                            .padding(end = 8.dp)
                    )

                    // Text Column
                    Column {
                        androidx.compose.material3.Text(
                            text = device.title,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                        )
                        androidx.compose.material3.Text(
                            text = device.description,
                            fontSize = 14.sp,
                        )
                    }
                }
            }
        }
    }
}