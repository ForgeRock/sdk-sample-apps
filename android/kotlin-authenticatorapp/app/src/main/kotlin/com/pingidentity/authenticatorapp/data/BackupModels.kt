/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.data

/**
 * Represents information about a backup file.
 */
data class BackupFileInfo(
    val name: String,
    val sizeBytes: Long,
    val timestamp: Long
)

/**
 * Represents information about a database.
 */
data class DatabaseInfo(
    val oathDbPath: String,
    val oathDbSize: Long,
    val oathBackupCount: Int,
    val pushDbPath: String,
    val pushDbSize: Long,
    val pushBackupCount: Int
)
