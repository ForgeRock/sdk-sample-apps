/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pingidentity.samples.pingonesample.R

/**
 * Full-size overlay composable that centres a transparent scanning window
 * with rounded corner brackets and a label above it.
 *
 * Designed to be placed inside a [androidx.compose.foundation.layout.Box]
 * that fills the camera preview area.
 */
@Composable
fun QrGrid(
    modifier: Modifier = Modifier,
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = modifier
            .fillMaxSize()
            .padding(horizontal = 40.dp),
    ) {
        Text(
            text = stringResource(R.string.qr_scanner_title),
            style = MaterialTheme.typography.titleMedium,
            color = Color.White,
            textAlign = TextAlign.Center,
        )
        Spacer(modifier = Modifier.height(16.dp))
        // Transparent scanning window — only corner brackets are drawn
        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(1f),
        ) {
            val stroke = 6.dp.toPx()
            val arm = 32.dp.toPx()
            val radius = 16.dp.toPx()
            val w = size.width
            val h = size.height

            val corners = listOf(
                Offset(0f, 0f) to (1f to 1f),    // top-left
                Offset(w, 0f) to (-1f to 1f),    // top-right
                Offset(w, h) to (-1f to -1f),    // bottom-right
                Offset(0f, h) to (1f to -1f),    // bottom-left
            )

            corners.forEach { (pivot, signs) ->
                val (sx, sy) = signs
                drawLine(
                    color = Color.White,
                    start = Offset(pivot.x + sx * radius, pivot.y),
                    end = Offset(pivot.x + sx * (radius + arm), pivot.y),
                    strokeWidth = stroke,
                    cap = StrokeCap.Round,
                )
                drawLine(
                    color = Color.White,
                    start = Offset(pivot.x, pivot.y + sy * radius),
                    end = Offset(pivot.x, pivot.y + sy * (radius + arm)),
                    strokeWidth = stroke,
                    cap = StrokeCap.Round,
                )
                drawArc(
                    color = Color.White,
                    startAngle = when {
                        sx > 0 && sy > 0 -> 180f
                        sx < 0 && sy > 0 -> 270f
                        sx < 0 && sy < 0 -> 0f
                        else -> 90f
                    },
                    sweepAngle = 90f,
                    useCenter = false,
                    topLeft = Offset(
                        pivot.x + sx * radius - radius,
                        pivot.y + sy * radius - radius,
                    ),
                    size = Size(radius * 2, radius * 2),
                    style = Stroke(
                        width = stroke,
                        cap = StrokeCap.Round,
                    ),
                )
            }
        }
    }
}
