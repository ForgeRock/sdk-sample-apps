/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.util

import java.time.Instant
import java.util.Date

/**
 * Helper function to format time ago string from a timestamp.
 */
fun getTimeAgoString(timestamp: Date): String {
    val now = Date.from(Instant.now()).time
    val diffInMillis = now - timestamp.time
    
    return when {
        diffInMillis < 60_000 -> "just now"
        diffInMillis < 3_600_000 -> "${diffInMillis / 60_000} minutes ago"
        diffInMillis < 86_400_000 -> "${diffInMillis / 3_600_000} hours ago"
        else -> "${diffInMillis / 86_400_000} days ago"
    }
}
