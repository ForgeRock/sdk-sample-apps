/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * A circular avatar composable that displays up to two initials derived from [seed].
 *
 * The background color is deterministically generated from the [seed] string using
 * its hash code mapped to an HSL hue, ensuring the same seed always produces the
 * same color across recompositions and app restarts.
 *
 * If no initials can be derived (e.g. the seed is blank), a `"?"` placeholder is shown.
 *
 * @param seed Arbitrary string used to derive the avatar initials and background color.
 *   Typically the account's display name, but any stable string produces a consistent result.
 * @param modifier Optional [Modifier] applied to the avatar container.
 * @param size The width and height of the avatar. Defaults to `40.dp`.
 */
@Composable
fun AccountAvatar(
    seed: String,
    modifier: Modifier = Modifier,
    size: Dp = 40.dp,
) {
    val backgroundColor = remember(seed) { generateAvatarColor(seed) }
    val initials = remember(seed) {
        seed.split(" ", ".")
            .filter { it.isNotEmpty() }
            .take(2)
            .joinToString("") { it.first().uppercaseChar().toString() }
            .ifEmpty { "?" }
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(RoundedCornerShape(8.dp))
            .background(backgroundColor),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = initials,
            style = MaterialTheme.typography.titleMedium,
            color = Color.White,
        )
    }
}

/**
 * Generates a deterministic [Color] from a string seed by mapping its hash code
 * to an HSL hue value in the range `[0, 360)`.
 *
 * @param seed The string used as input for color generation.
 * @return A [Color] with saturation `0.6` and lightness `0.5`.
 */
private fun generateAvatarColor(seed: String): Color {
    val hue = Math.floorMod(seed.hashCode(), 360)
    return Color.hsl(hue.toFloat(), 0.6f, 0.5f)
}
