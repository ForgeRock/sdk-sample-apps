/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import coil.compose.SubcomposeAsyncImage
import coil.request.ImageRequest
import kotlin.math.absoluteValue

/**
 * Composable for displaying an account avatar image or a colored background with initials
 */
@Composable
fun AccountAvatar(
    issuer: String,
    accountName: String,
    imageUrl: String? = null,
    size: androidx.compose.ui.unit.Dp = 40.dp,
    modifier: Modifier = Modifier
) {
    val backgroundColor = generateBackgroundColor(issuer, accountName)
    val initials = getInitials(issuer)

    Box(
        modifier = modifier
            .size(size)
            .background(
                color = backgroundColor,
                shape = RoundedCornerShape(8.dp)
            ),
        contentAlignment = Alignment.Center
    ) {
        if (imageUrl != null) {
            SubcomposeAsyncImage(
                model = ImageRequest.Builder(LocalContext.current)
                    .data(imageUrl)
                    .crossfade(true)
                    .build(),
                contentDescription = "Account logo",
                modifier = Modifier
                    .fillMaxSize()
                    .clip(RoundedCornerShape(8.dp)),
                contentScale = ContentScale.Crop,
                loading = {
                    LoadingIndicator()
                },
                error = {
                    InitialsText(initials)
                }
            )
        } else {
            // Fallback to initials if no image URL
            InitialsText(initials)
        }
    }
}

@Composable
fun InitialsText(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleLarge,
        color = MaterialTheme.colorScheme.onPrimary
    )
}

@Composable
fun LoadingIndicator() {
    CircularProgressIndicator(
        modifier = Modifier.size(24.dp),
        color = MaterialTheme.colorScheme.onPrimary,
        strokeWidth = 2.dp
    )
}

/**
 * Generates a background color from the issuer and account name.
 */
private fun generateBackgroundColor(issuer: String, accountName: String): Color {
    val hash = (issuer.hashCode() + accountName.hashCode()).absoluteValue % 360
    return Color.hsl(hash.toFloat(), 0.6f, 0.55f)
}

/**
 * Gets the initials from a string.
 */
private fun getInitials(text: String): String {
    return text.split(" ")
        .filter { it.isNotEmpty() }
        .take(2)
        .joinToString("") { it.first().uppercaseChar().toString() }
}

