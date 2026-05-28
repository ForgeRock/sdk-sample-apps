/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.managers

import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import com.pingidentity.authenticatorapp.AuthenticatorApp
import com.pingidentity.authenticatorapp.data.BackupFileInfo
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.data.PushNotificationItem
import com.pingidentity.authenticatorapp.data.toUiItems
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import com.pingidentity.mfa.push.PushClient
import com.pingidentity.mfa.push.PushCredential
import com.pingidentity.mfa.push.PushNotification
import com.pingidentity.mfa.push.storage.SQLPushStorage
import java.io.File

/**
 * Manager class for handling all Push credential and notification operations.
 * Encapsulates Push-specific business logic and state management.
 *
 * @param pushClient The Push MFA client instance
 * @param pushStorage The Push storage instance (optional, for backup operations)
 * @param diagnosticLogger DiagnosticLogger for logging
 */
class PushManager(
    private var pushClient: PushClient? = null,
    private var pushStorage: SQLPushStorage? = null,
    private val diagnosticLogger: DiagnosticLogger
) {
    
    private val _pushCredentials = MutableStateFlow<List<PushCredential>>(emptyList())
    val pushCredentials: StateFlow<List<PushCredential>> = _pushCredentials.asStateFlow()
    
    private val _isLoadingPushCredentials = MutableStateFlow(false)
    val isLoadingPushCredentials: StateFlow<Boolean> = _isLoadingPushCredentials.asStateFlow()
    
    private val _pushNotifications = MutableStateFlow<List<PushNotification>>(emptyList())
    val pushNotifications: StateFlow<List<PushNotification>> = _pushNotifications.asStateFlow()
    
    private val _pendingNotifications = MutableStateFlow<List<PushNotification>>(emptyList())
    val pendingNotifications: StateFlow<List<PushNotification>> = _pendingNotifications.asStateFlow()
    
    private val _isLoadingNotifications = MutableStateFlow(false)
    val isLoadingNotifications: StateFlow<Boolean> = _isLoadingNotifications.asStateFlow()
    
    private val _pushNotificationItems = MutableStateFlow<List<PushNotificationItem>>(emptyList())
    val pushNotificationItems: StateFlow<List<PushNotificationItem>> = _pushNotificationItems.asStateFlow()
    
    private val _pendingNotificationItems = MutableStateFlow<List<PushNotificationItem>>(emptyList())
    val pendingNotificationItems: StateFlow<List<PushNotificationItem>> = _pendingNotificationItems.asStateFlow()
    
    private val _lastAddedPushCredential = MutableStateFlow<PushCredential?>(null)
    val lastAddedPushCredential: StateFlow<PushCredential?> = _lastAddedPushCredential.asStateFlow()

    /**
     * Sets the Push client instance and optionally the storage instance.
     * 
     * @param client The Push client instance
     * @param storage Optional storage instance for backup operations
     */
    fun setClient(client: PushClient, storage: SQLPushStorage? = null) {
        this.pushClient = client
        this.pushStorage = storage
    }

    /**
     * Loads all Push credentials from the SDK.
     */
    suspend fun loadCredentials(): Result<List<PushCredential>> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        _isLoadingPushCredentials.value = true
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Loading Push credentials from PushClient")
                client.getCredentials()
            }
            
            result.onSuccess { credentials ->
                _pushCredentials.value = credentials
                // Update notification items when credentials change
                updateNotificationItems()
            }
            
            _isLoadingPushCredentials.value = false
            result
        } catch (e: Exception) {
            _isLoadingPushCredentials.value = false
            Result.failure(e)
        }
    }

    /**
     * Adds a Push credential from a URI.
     */
    suspend fun addCredentialFromUri(uri: String): Result<PushCredential> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Adding Push credential from URI: ${maskUri(uri)}")
                client.addCredentialFromUri(uri)
            }
            
            result.onSuccess { credential ->
                _lastAddedPushCredential.value = credential
                // Reload credentials to refresh the list
                loadCredentials()
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Removes a Push credential from the SDK.
     */
    suspend fun removeCredential(credentialId: String): Result<Boolean> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Removing Push credential: $credentialId")
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
     * Updates a Push credential in the SDK.
     */
    suspend fun updateCredential(credential: PushCredential): Result<PushCredential> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Updating Push credential: $credential")
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
     * Loads pending push notifications from the SDK.
     */
    suspend fun loadPushNotifications(): Result<List<PushNotification>> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        _isLoadingNotifications.value = true
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Loading push notifications from PushClient")
                client.getPendingNotifications()
            }
            
            result.onSuccess { notifications ->
                _pendingNotifications.value = notifications
                updateNotificationItems()
            }
            
            _isLoadingNotifications.value = false
            result
        } catch (e: Exception) {
            _isLoadingNotifications.value = false
            Result.failure(e)
        }
    }

    /**
     * Loads all push notifications (not just pending ones).
     */
    suspend fun loadAllPushNotifications(): Result<List<PushNotification>> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        _isLoadingNotifications.value = true
        return try {
            val result = withContext(Dispatchers.IO) {
                client.getAllNotifications()
            }
            
            result.onSuccess { allNotifications ->
                val pendingNotifications = allNotifications.filter { it.pending }
                _pushNotifications.value = allNotifications
                _pendingNotifications.value = pendingNotifications
                updateNotificationItems()
            }
            
            _isLoadingNotifications.value = false
            result
        } catch (e: Exception) {
            _isLoadingNotifications.value = false
            Result.failure(e)
        }
    }

    /**
     * Approves a push notification.
     */
    suspend fun approveNotification(notificationId: String): Result<Boolean> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Approving push notification: $notificationId")
                client.approveNotification(notificationId)
            }
            
            result.onSuccess { success ->
                if (success) {
                    // Reload notifications after approving
                    loadPushNotifications()
                    loadAllPushNotifications()
                }
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Approves a push notification with a challenge response.
     */
    suspend fun approveChallengeNotification(notificationId: String, challengeResponse: String): Result<Boolean> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Approving challenge push notification: $notificationId")
                client.approveChallengeNotification(notificationId, challengeResponse)
            }
            
            result.onSuccess { success ->
                if (success) {
                    // Reload notifications after approving
                    loadPushNotifications()
                    loadAllPushNotifications()
                }
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Denies a push notification.
     */
    suspend fun denyNotification(notificationId: String): Result<Boolean> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Denying push notification: $notificationId")
                client.denyNotification(notificationId)
            }
            
            result.onSuccess { success ->
                if (success) {
                    // Reload notifications after denying
                    loadPushNotifications()
                    loadAllPushNotifications()
                }
            }
            
            result
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Cleans up old notifications.
     */
    suspend fun cleanupNotifications(): Result<Int> {
        val client = pushClient ?: return Result.failure(Exception("Push client not initialized"))
        return try {
            withContext(Dispatchers.IO) {
                client.cleanupNotifications()
            }.also { result ->
                result.onSuccess {
                    // Reload notifications after cleanup
                    loadPushNotifications()
                }
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Gets the current device token used for push notifications.
     */
    suspend fun getDeviceToken(): Result<String?> {
        val client = pushClient
        return try {
            withContext(Dispatchers.IO) {
                client?.getDeviceToken() ?: Result.success("Not available")
            }.also { result ->
                result.onSuccess { token ->
                    diagnosticLogger.d("Retrieved device token from PushClient: $token")
                }.onFailure { e ->
                    diagnosticLogger.e("Error retrieving device token from PushClient: ${e.message}")
                }
            }
        } catch (e: Exception) {
            diagnosticLogger.e("Error retrieving device token from PushClient: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Forces a renewal of the Firebase device token.
     */
    suspend fun forceDeviceTokenRenew(): Result<Unit> {
        return try {
            diagnosticLogger.d("Attempting to force device token renew.")
            
            // Delete current token
            val deleteResult = deleteDeviceToken()
            if (!deleteResult.getOrDefault(false)) {
                return Result.failure(Exception("Failed to delete existing device token, renewal aborted."))
            }
            
            diagnosticLogger.d("Previous device token deleted successfully. Fetching new token.")
            
            // Get new token
            val newToken = suspendCancellableCoroutine<String?> { continuation ->
                FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        continuation.resume(task.result)
                    } else {
                        continuation.resumeWithException(task.exception ?: Exception("Failed to get token"))
                    }
                }
            }
            
            if (newToken == null) {
                return Result.failure(Exception("Failed to fetch new FCM token (token is null)"))
            }
            
            diagnosticLogger.d("New FCM token received. Setting it in PushClient.")
            
            // Set new token in PushClient
            val setResult = withContext(Dispatchers.IO) {
                val client = pushClient
                client?.setDeviceToken(newToken)
            }
            
            if (setResult != null) {
                setResult.onSuccess {
                    diagnosticLogger.d("Successfully set new device token in PushClient.")
                }.onFailure { e ->
                    diagnosticLogger.e("Failed to set new device token in PushClient: ${e.message}")
                }
                setResult.map { }
            } else {
                val errorMessage = "PushClient is not available or does not support setDeviceToken."
                diagnosticLogger.e(errorMessage)
                Result.failure(Exception(errorMessage))
            }
        } catch (e: Exception) {
            diagnosticLogger.e("Exception while setting new device token: ${e.message}")
            Result.failure(e)
        }
    }

    /**
     * Gets a specific push notification item by its ID.
     */
    fun getNotificationItemById(notificationId: String): PushNotificationItem? {
        return _pushNotificationItems.value.find { it.notification.id == notificationId }
    }

    /**
     * Clears the last added Push credential.
     */
    fun clearLastAddedCredential() {
        _lastAddedPushCredential.value = null
    }

    /**
     * Updates the notification items in the state based on current push notifications.
     */
    private fun updateNotificationItems() {
        val pendingItems = _pendingNotifications.value.toUiItems(_pushCredentials.value)
        val allItems = _pushNotifications.value.toUiItems(_pushCredentials.value)

        _pushNotificationItems.value = allItems
        _pendingNotificationItems.value = pendingItems

        // Log the number of pending notifications
        Log.d("PushManager", "Pending notifications: ${pendingItems.size}")
    }

    /**
     * Deletes the Firebase device token.
     */
    private suspend fun deleteDeviceToken(): Result<Boolean> {
        return try {
            suspendCancellableCoroutine { continuation ->
                FirebaseMessaging.getInstance().deleteToken().addOnCompleteListener { task ->
                    if (task.isSuccessful) {
                        continuation.resume(Unit)
                    } else {
                        continuation.resumeWithException(task.exception ?: Exception("Failed to delete token"))
                    }
                }
            }
            diagnosticLogger.d("Firebase device token deleted successfully.")
            Result.success(true)
        } catch (e: Exception) {
            diagnosticLogger.e("Firebase device token deletion failed: ${e.message}")
            Result.success(false)
        }
    }

    /**
     * Closes the Push client and releases resources.
     */
    suspend fun close() {
        try {
            pushClient?.close()
        } catch (e: Exception) {
            diagnosticLogger.e("Error closing Push client", e)
        }
    }

    /**
     * Masks sensitive information in a URI for logging.
     */
    private fun maskUri(uri: String): String {
        return uri.replace(Regex("secret=[^&]*"), "secret=*****")
    }

    /**
     * Gets the list of backup files for Push database.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun getBackupFiles(): List<BackupFileInfo> {
        return withContext(Dispatchers.IO) {
            try {
                val storage = pushStorage
                if (storage == null) {
                    diagnosticLogger.w("Push storage not available. Pass storage to setClient() to enable backup operations.")
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
                diagnosticLogger.e("Error getting Push backup files", e)
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
     * Restores Push database from the latest backup.
     * This method creates a temporary storage instance to access backup files without requiring
     * full database initialization. This allows restoration even when the database is corrupted.
     * 
     * @param context Android context needed to create temporary storage instance
     */
    suspend fun restoreFromBackup(context: android.content.Context): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                // Try to use existing storage if available
                var storage = pushStorage
                
                // If storage is not available (e.g., initialization failed), create a temporary instance
                // just for accessing backup restoration functionality using centralized config
                if (storage == null) {
                    diagnosticLogger.i("Creating temporary storage instance for backup restoration")
                    storage = AuthenticatorApp.createPushStorage(
                        context = context,
                        autoRestoreFromBackup = false,
                        allowDestructiveRecovery = false,
                        logger = diagnosticLogger
                    )
                }
                
                val success = storage.attemptBackupRestoration()
                
                if (success) {
                    diagnosticLogger.i("Successfully restored Push database from backup")
                } else {
                    diagnosticLogger.w("Failed to restore Push database from backup or no backups available")
                }
                
                success
            } catch (e: Exception) {
                diagnosticLogger.e("Error restoring Push backup", e)
                false
            }
        }
    }
    
    /**
     * Creates a manual backup of the PUSH database.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun createManualBackup() {
        return withContext(Dispatchers.IO) {
            try {
                val storage = pushStorage
                if (storage == null) {
                    diagnosticLogger.w("Push storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext
                }
                
                storage.createDatabaseBackup()
                diagnosticLogger.i("Manual Push backup created successfully")
            } catch (e: Exception) {
                diagnosticLogger.e("Error creating manual Push backup", e)
                throw e
            }
        }
    }
    
    /**
     * Makes the Push database read-only for testing error handling.
     * Creates a backup first to ensure recovery is possible.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun makeDatabaseReadOnly() {
        return withContext(Dispatchers.IO) {
            try {
                val storage = pushStorage
                if (storage == null) {
                    diagnosticLogger.w("Push storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext
                }
                
                // Create backup FIRST to ensure recovery is possible
                diagnosticLogger.i("Creating backup before making database read-only")
                storage.createDatabaseBackup()
                diagnosticLogger.i("Backup created successfully")
                
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_push.db"
                
                if (context != null) {
                    val dbFile = context.getDatabasePath(databaseName)
                    if (dbFile.exists()) {
                        pushClient?.close()
                        dbFile.setReadOnly()
                        diagnosticLogger.w("Made Push database read-only for testing: ${dbFile.absolutePath}")
                        diagnosticLogger.w("⚠️ App will fail on next write attempt")
                    } else {
                        diagnosticLogger.w("Push database file not found: ${dbFile.absolutePath}")
                    }
                } else {
                    diagnosticLogger.w("Unable to access storage context")
                }
            } catch (e: Exception) {
                diagnosticLogger.e("Error making Push database read-only", e)
                throw e
            }
        }
    }
    
    /**
     * Corrupts the Push database for testing error handling.
     * Creates a backup first to ensure recovery is possible.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun corruptDatabase() {
        return withContext(Dispatchers.IO) {
            try {
                val storage = pushStorage
                if (storage == null) {
                    diagnosticLogger.w("Push storage not available. Pass storage to setClient() to enable backup operations.")
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
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_push.db"
                
                if (context != null) {
                    val dbFile = context.getDatabasePath(databaseName)
                    if (dbFile.exists()) {
                        pushClient?.close()
                        dbFile.writeBytes(ByteArray(1024) { 0xFF.toByte() })
                        diagnosticLogger.w("Corrupted Push database for testing: ${dbFile.absolutePath}")
                        diagnosticLogger.w("⚠️ App will need to restore from backup on next launch")
                    } else {
                        diagnosticLogger.w("Push database file not found: ${dbFile.absolutePath}")
                    }
                } else {
                    diagnosticLogger.w("Unable to access storage context")
                }
            } catch (e: Exception) {
                diagnosticLogger.e("Error corrupting Push database", e)
                throw e
            }
        }
    }
    
    /**
     * Clears all Push backup files.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun clearBackups(): Int {
        return withContext(Dispatchers.IO) {
            try {
                val storage = pushStorage
                if (storage == null) {
                    diagnosticLogger.w("Push storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext 0
                }
                
                val backups = getBackupFiles()
                if (backups.isEmpty()) {
                    diagnosticLogger.i("No Push backup files to clear")
                    return@withContext 0
                }
                
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_push.db"
                
                if (context != null) {
                    val dbDir = context.getDatabasePath(databaseName).parentFile
                    var deletedCount = 0
                    
                    backups.forEach { backup ->
                        val backupFile = File(dbDir, backup.name)
                        if (backupFile.exists() && backupFile.delete()) {
                            deletedCount++
                            diagnosticLogger.d("Deleted Push backup: ${backup.name}")
                        }
                    }
                    
                    diagnosticLogger.i("Cleared $deletedCount Push backup files")
                    return@withContext deletedCount
                }
                
                diagnosticLogger.w("Unable to access storage context for clearing backups")
                0
            } catch (e: Exception) {
                diagnosticLogger.e("Error clearing Push backups", e)
                0
            }
        }
    }
    
    /**
     * Gets information about the Push database.
     * Requires storage instance to be set via setClient() or constructor.
     */
    suspend fun getDatabaseInfo(): DbInfo {
        return withContext(Dispatchers.IO) {
            try {
                val storage = pushStorage
                if (storage == null) {
                    diagnosticLogger.w("Push storage not available. Pass storage to setClient() to enable backup operations.")
                    return@withContext DbInfo(path = "unknown", size = 0L, backupCount = 0)
                }
                
                val contextField = storage.javaClass.superclass?.getDeclaredField("context")
                contextField?.isAccessible = true
                val context = contextField?.get(storage) as? android.content.Context
                
                val databaseNameField = storage.javaClass.superclass?.getDeclaredField("databaseName")
                databaseNameField?.isAccessible = true
                val databaseName = databaseNameField?.get(storage) as? String ?: "pingidentity_push.db"
                
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
                    path = "pingidentity_push.db",
                    size = 0L,
                    backupCount = 0
                )
            } catch (e: Exception) {
                diagnosticLogger.e("Error getting Push database info", e)
                DbInfo(path = "unknown", size = 0L, backupCount = 0)
            }
        }
    }
}