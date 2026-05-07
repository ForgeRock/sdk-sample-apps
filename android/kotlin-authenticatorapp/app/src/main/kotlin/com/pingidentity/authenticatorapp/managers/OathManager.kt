/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.managers

import com.pingidentity.authenticatorapp.AuthenticatorApp
import com.pingidentity.authenticatorapp.data.BackupFileInfo
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import com.pingidentity.mfa.oath.OathCodeInfo
import com.pingidentity.mfa.oath.OathCredential
import com.pingidentity.mfa.oath.OathClient
import com.pingidentity.mfa.oath.storage.SQLOathStorage
import java.io.File

/**
 * Manager class for handling all OATH credential operations.
 * Encapsulates OATH-specific business logic and state management.
 *
 * @param oathClient The OATH MFA client instance
 * @param oathStorage The OATH storage instance (optional, for backup operations)
 * @param diagnosticLogger DiagnosticLogger for logging
 */
class OathManager(
    private var oathClient: OathClient? = null,
    private var oathStorage: SQLOathStorage? = null,
    private val diagnosticLogger: DiagnosticLogger
) {
    
    private val _oathCredentials = MutableStateFlow<List<OathCredential>>(emptyList())
    val oathCredentials: StateFlow<List<OathCredential>> = _oathCredentials.asStateFlow()
    
    private val _isLoadingOathCredentials = MutableStateFlow(false)
    val isLoadingOathCredentials: StateFlow<Boolean> = _isLoadingOathCredentials.asStateFlow()
    
    private val _generatedCodes = MutableStateFlow<Map<String, OathCodeInfo>>(emptyMap())
    val generatedCodes: StateFlow<Map<String, OathCodeInfo>> = _generatedCodes.asStateFlow()
    
    private val _lastAddedOathCredential = MutableStateFlow<OathCredential?>(null)
    val lastAddedOathCredential: StateFlow<OathCredential?> = _lastAddedOathCredential.asStateFlow()

    /**
     * Sets the OATH client instance and optionally the storage instance.
     * 
     * @param client The OATH client instance
     * @param storage Optional storage instance for backup operations
     */
    fun setClient(client: OathClient, storage: SQLOathStorage? = null) {
        this.oathClient = client
        this.oathStorage = storage
    }

    /**
     * Loads all OATH credentials from the SDK.
     */
    suspend fun loadCredentials(): Result<List<OathCredential>> {
        val client = oathClient ?: return Result.failure(Exception("OATH client not initialized"))
        _isLoadingOathCredentials.value = true
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Loading OATH credentials from OathClient")
                client.getCredentials()
            }
            
            result.onSuccess { credentials ->
                _oathCredentials.value = credentials
            }
            
            _isLoadingOathCredentials.value = false
            result
        } catch (e: Exception) {
            _isLoadingOathCredentials.value = false
            Result.failure(e)
        }
    }

    /**
     * Adds an OATH credential from a URI.
     */
    suspend fun addCredentialFromUri(uri: String): Result<OathCredential> {
        val client = oathClient ?: return Result.failure(Exception("OATH client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Adding OATH credential from URI: ${maskUri(uri)}")
                client.addCredentialFromUri(uri)
            }
            
            result.onSuccess { credential ->
                _lastAddedOathCredential.value = credential
                // Reload credentials to refresh the list
                loadCredentials()
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Removes an OATH credential from the SDK.
     */
    suspend fun removeCredential(credentialId: String): Result<Boolean> {
        val client = oathClient ?: return Result.failure(Exception("OATH client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Removing OATH credential: $credentialId")
                client.deleteCredential(credentialId)
            }
            
            result.onSuccess { removed ->
                if (removed) {
                    // Reload credentials to refresh the list
                    loadCredentials()
                }
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Updates an OATH credential in the SDK.
     */
    suspend fun updateCredential(credential: OathCredential): Result<OathCredential> {
        val client = oathClient ?: return Result.failure(Exception("OATH client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Updating OATH credential: $credential")
                client.saveCredential(credential)
            }
            
            result.onSuccess {
                // Reload credentials to refresh the list
                loadCredentials()
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Generates a code for a credential.
     */
    suspend fun generateCode(credentialId: String): Result<OathCodeInfo> {
        val client = oathClient ?: return Result.failure(Exception("OATH client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                client.generateCodeWithValidity(credentialId)
            }
            
            result.onSuccess { codeInfo ->
                val updatedCodes = _generatedCodes.value.toMutableMap()
                updatedCodes[credentialId] = codeInfo
                _generatedCodes.value = updatedCodes
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Clears the last added OATH credential.
     */
    fun clearLastAddedCredential() {
        _lastAddedOathCredential.value = null
    }

    /**
     * Closes the OATH client and releases resources.
     */
    suspend fun close() {
        try {
            oathClient?.close()
        } catch (e: Exception) {
            diagnosticLogger.e("Error closing OATH client", e)
        }
    }

    /**
     * Masks sensitive information in a URI for logging.
     */
    private fun maskUri(uri: String): String {
        return uri.replace(Regex("secret=[^&]*"), "secret=*****")
    }

    /**
     * Gets the list of backup files for OATH database.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun getBackupFiles(): List<BackupFileInfo> {
        return withContext(Dispatchers.IO) {
            try {
                val storage = oathStorage
                if (storage == null) {
                    diagnosticLogger.w("OATH storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext emptyList()
                }
                
                val backupFiles = storage.listBackupFiles()
                
                backupFiles.map { file ->
                    BackupFileInfo(
                        name = file.name,
                        sizeBytes = file.length(),
                        timestamp = parseBackupTimestamp(file.name)
                    )
                }
            } catch (e: Exception) {
                diagnosticLogger.e("Error getting OATH backup files", e)
                emptyList()
            }
        }
    }
    
    /**
     * Parses timestamp from backup filename.
     * Format: {databaseName}_backup_{timestamp}.db
     */
    private fun parseBackupTimestamp(filename: String): Long {
        return try {
            val timestampStr = filename
                .substringAfter("_backup_")
                .substringBefore(".db")
            timestampStr.toLongOrNull() ?: 0L
        } catch (_: Exception) {
            0L
        }
    }
    
    /**
     * Restores OATH database from the latest backup.
     * This method creates a temporary storage instance to access backup files without requiring
     * full database initialization. This allows restoration even when the database is corrupted.
     * 
     * @param context Android context needed to create temporary storage instance
     */
    suspend fun restoreFromBackup(context: android.content.Context): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Try to use existing storage if available
                var storage = oathStorage
                
                // If storage is not available (e.g., initialization failed), create a temporary instance
                // just for accessing backup restoration functionality using centralized config
                if (storage == null) {
                    diagnosticLogger.i("Creating temporary storage instance for backup restoration")
                    storage = AuthenticatorApp.createOathStorage(
                        context = context,
                        autoRestoreFromBackup = false,
                        allowDestructiveRecovery = false,
                        logger = diagnosticLogger
                    )
                }
                
                val success = storage.attemptBackupRestoration()
                
                if (success) {
                    diagnosticLogger.i("Successfully restored OATH database from backup")
                } else {
                    diagnosticLogger.w("Failed to restore OATH database from backup or no backups available")
                }
                
                success
            } catch (e: Exception) {
                diagnosticLogger.e("Error restoring OATH backup", e)
                false
            }
        }
    }
    
    /**
     * Corrupts the OATH database for testing error handling.
     * Creates a backup first to ensure recovery is possible.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun corruptDatabase() {
        return withContext(Dispatchers.IO) {
            try {
                val storage = oathStorage
                if (storage == null) {
                    diagnosticLogger.w("OATH storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext
                }
                
                // Create backup FIRST to ensure recovery is possible
                diagnosticLogger.i("Creating backup before corrupting database")
                storage.createDatabaseBackup()
                diagnosticLogger.i("Backup created successfully")
                
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_oath.db"
                
                if (context != null) {
                    val dbFile = context.getDatabasePath(databaseName)
                    if (dbFile.exists()) {
                        oathClient?.close()
                        dbFile.writeBytes(ByteArray(1024) { 0xFF.toByte() })
                        diagnosticLogger.w("Corrupted OATH database for testing: ${dbFile.absolutePath}")
                        diagnosticLogger.w("⚠️ App will need to restore from backup on next launch")
                    } else {
                        diagnosticLogger.w("OATH database file not found: ${dbFile.absolutePath}")
                    }
                } else {
                    diagnosticLogger.w("Unable to access storage context")
                }
            } catch (e: Exception) {
                diagnosticLogger.e("Error corrupting OATH database", e)
                throw e
            }
        }
    }
    
    /**
     * Creates a manual backup of the OATH database.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun createManualBackup() {
        return withContext(Dispatchers.IO) {
            try {
                val storage = oathStorage
                if (storage == null) {
                    diagnosticLogger.w("OATH storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext
                }
                
                storage.createDatabaseBackup()
                diagnosticLogger.i("Manual OATH backup created successfully")
            } catch (e: Exception) {
                diagnosticLogger.e("Error creating manual OATH backup", e)
                throw e
            }
        }
    }
    
    /**
     * Makes the OATH database read-only for testing.
     * Creates a backup first to ensure recovery is possible.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun makeDatabaseReadOnly() {
        return withContext(Dispatchers.IO) {
            try {
                val storage = oathStorage
                if (storage == null) {
                    diagnosticLogger.w("OATH storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext
                }
                
                // Create backup FIRST to ensure recovery is possible
                diagnosticLogger.i("Creating backup before making database read-only")
                storage.createDatabaseBackup()
                diagnosticLogger.i("Backup created successfully")
                
                // Access context and database name via reflection (storage internals)
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_oath.db"
                
                if (context != null) {
                    val dbFile = context.getDatabasePath(databaseName)
                    if (dbFile.exists()) {
                        dbFile.setReadOnly()
                        diagnosticLogger.i("Made OATH database read-only: ${dbFile.absolutePath}")
                        diagnosticLogger.w("⚠️ App will need to restore from backup on next launch")
                    } else {
                        diagnosticLogger.w("OATH database file not found: ${dbFile.absolutePath}")
                    }
                } else {
                    diagnosticLogger.w("Unable to access storage context")
                }
            } catch (e: Exception) {
                diagnosticLogger.e("Error making OATH database read-only", e)
                throw e
            }
        }
    }
    
    /**
     * Clears all OATH backup files.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun clearBackups(): Int {
        return withContext(Dispatchers.IO) {
            try {
                val storage = oathStorage
                if (storage == null) {
                    diagnosticLogger.w("OATH storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext 0
                }
                
                val backups = getBackupFiles()
                if (backups.isEmpty()) {
                    diagnosticLogger.i("No OATH backup files to clear")
                    return@withContext 0
                }
                
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_oath.db"
                
                if (context != null) {
                    val dbDir = context.getDatabasePath(databaseName).parentFile
                    var deletedCount = 0
                    
                    backups.forEach { backup ->
                        val backupFile = File(dbDir, backup.name)
                        if (backupFile.exists() && backupFile.delete()) {
                            deletedCount++
                            diagnosticLogger.d("Deleted OATH backup: ${backup.name}")
                        }
                    }
                    
                    diagnosticLogger.i("Cleared $deletedCount OATH backup files")
                    return@withContext deletedCount
                }
                
                diagnosticLogger.w("Unable to access storage context for clearing backups")
                0
            } catch (e: Exception) {
                diagnosticLogger.e("Error clearing OATH backups", e)
                0
            }
        }
    }
    
    /**
     * Gets information about the OATH database.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun getDatabaseInfo(): DbInfo {
        return withContext(Dispatchers.IO) {
            try {
                val storage = oathStorage
                if (storage == null) {
                    diagnosticLogger.w("OATH storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext DbInfo(path = "unknown", size = 0L, backupCount = 0)
                }
                
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_oath.db"
                
                if (context != null) {
                    val dbFile = context.getDatabasePath(databaseName)
                    val size = if (dbFile.exists()) dbFile.length() else 0L
                    val backups = getBackupFiles()
                    
                    return@withContext DbInfo(
                        path = databaseName,
                        size = size,
                        backupCount = backups.size
                    )
                }
                
                DbInfo(
                    path = "pingidentity_oath.db",
                    size = 0L,
                    backupCount = 0
                )
            } catch (e: Exception) {
                diagnosticLogger.e("Error getting OATH database info", e)
                DbInfo(path = "unknown", size = 0L, backupCount = 0)
            }
        }
    }
}

/**
 * Database information.
 */
data class DbInfo(
    val path: String,
    val size: Long,
    val backupCount: Int
)