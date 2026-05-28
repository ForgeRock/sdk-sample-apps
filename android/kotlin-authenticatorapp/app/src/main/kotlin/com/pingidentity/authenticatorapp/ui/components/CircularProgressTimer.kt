/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Box
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke

/**
 * A composable that displays a circular progress indicator that animates to the given progress value.
 * This is useful for showing a countdown timer or similar progress indication.
 *
 * @param progress The current progress value between 0f and 1f.
 * @param modifier Optional modifier to apply to the composable.
 */
@Composable
fun CircularProgressTimer(
    progress: Float,
    modifier: Modifier = Modifier
) {
    val animatedProgress = remember(progress) {
        Animatable(initialValue = progress)
    }

    LaunchedEffect(progress) {
        animatedProgress.animateTo(
            targetValue = progress,
            animationSpec = tween(durationMillis = 500, easing = LinearEasing)
        )
    }

    val color = MaterialTheme.colorScheme.primary
    val trackColor = MaterialTheme.colorScheme.surfaceVariant

    Box(
        modifier = modifier.drawBehind {
            // Draw background track
            drawArc(
                color = trackColor,
                startAngle = 0f,
                sweepAngle = 360f,
                useCenter = false,
                style = Stroke(width = 10f, cap = StrokeCap.Round)
            )

            // Draw progress
            drawArc(
                color = color,
                startAngle = -90f,
                sweepAngle = 360f * (1f - animatedProgress.value),
                useCenter = false,
                style = Stroke(width = 10f, cap = StrokeCap.Round)
            )
        }
    )
}