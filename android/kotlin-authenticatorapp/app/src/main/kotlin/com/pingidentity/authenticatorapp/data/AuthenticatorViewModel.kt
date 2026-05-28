/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.data

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.managers.AccountGroupingManager
import com.pingidentity.authenticatorapp.managers.OathManager
import com.pingidentity.authenticatorapp.managers.PushManager
import com.pingidentity.authenticatorapp.managers.TestAccountFactory
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.mfa.commons.exception.CredentialLockedException
import com.pingidentity.mfa.commons.exception.DuplicateCredentialException
import com.pingidentity.mfa.oath.OathCodeInfo
import com.pingidentity.mfa.oath.OathCredential
import com.pingidentity.mfa.push.PushCredential
import com.pingidentity.mfa.push.PushNotification
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Enum representing different types of initialization errors.
 */
enum class InitializationErrorType {
    OATH_DATABASE_CORRUPTED,
    PUSH_DATABASE_CORRUPTED,
    BOTH_DATABASES_CORRUPTED,
    OATH_INITIALIZATION_FAILED,
    PUSH_INITIALIZATION_FAILED,
    JOURNEY_INITIALIZATION_FAILED,
    FIREBASE_CONFIGURATION_ERROR,
    UNKNOWN_ERROR
}

/**
 * Represents an error from a specific component during initialization.
 */
data class ComponentError(
    val component: String,  // "OATH", "Push", "Journey", "Firebase"
    val exception: Exception
)

/**
 * Data class representing an initialization error with recovery options.
 */
data class InitializationError(
    val type: InitializationErrorType,
    val message: String,
    val errors: List<ComponentError> = emptyList(),
    val canRestoreFromBackup: Boolean = false,
    val canUseDestructiveRecovery: Boolean = false,
    val timestamp: Long = System.currentTimeMillis()
)

/**
 * ViewModel for the Authenticator app.
 * Coordinates between different managers and handles UI-specific logic.
 * 
 * @param application The application context for accessing app-level resources
 * @param userPreferences Injected UserPreferences dependency for settings management
 * @param oathManager Manager for OATH credential operations
 * @param pushManager Manager for Push credential and notification operations
 * @param accountGroupingManager Manager for account grouping and ordering
 * @param testAccountFactory Factory for creating test accounts
 */
class AuthenticatorViewModel(
    application: Application,
    private val userPreferences: UserPreferences,
    private val oathManager: OathManager,
    private val pushManager: PushManager,
    private val accountGroupingManager: AccountGroupingManager,
    private val testAccountFactory: TestAccountFactory
) : AndroidViewModel(application), ViewModelProvider.Factory {

    private val _uiState = MutableStateFlow(AuthenticatorUiState())
    private val diagnosticLogger = DiagnosticLogger
    
    // Track loading states to batch account group updates
    private var oathCredentialsLoaded = false
    private var pushCredentialsLoaded = false

    val uiState: StateFlow<AuthenticatorUiState> = _uiState.asStateFlow()

    // Expose all settings preferences as StateFlows
    val copyOtp: StateFlow<Boolean>
        get() = userPreferences.copyOtpFlow

    val tapToReveal: StateFlow<Boolean>
        get() = userPreferences.tapToRevealFlow

    val combineAccounts: StateFlow<Boolean>
        get() = userPreferences.combineAccountsFlow

    val diagnosticLogging: StateFlow<Boolean>
        get() = userPreferences.diagnosticLoggingFlow

    val testMode: StateFlow<Boolean>
        get() = userPreferences.testModeFlow

    val themeMode: StateFlow<ThemeMode>
        get() = userPreferences.themeModeFlow

    val destructiveRecovery: StateFlow<Boolean>
        get() = userPreferences.destructiveRecoveryFlow

    val autoRestoreFromBackup: StateFlow<Boolean>
        get() = userPreferences.autoRestoreFromBackupFlow


    /**
     * Initializes the ViewModel by setting up state flows and loading initial data.
     */
    init {
        setupStateFlows()
        loadInitialData()
    }

    /**
     * Sets up the state flows to observe manager states and update UI state accordingly.
     */
    private fun setupStateFlows() {
        // Observe credential changes and update account groups
        viewModelScope.launch {
            combine(
                oathManager.oathCredentials,
                pushManager.pushCredentials
            ) { oathCreds, pushCreds ->
                Pair(oathCreds, pushCreds)
            }.collect { (oathCreds, pushCreds) ->
                accountGroupingManager.updateAccountGroups(oathCreds, pushCreds)
                // Update UI state when credentials change
                updateUiStateFromManagers()
            }
        }
        
        // Observe combine accounts setting changes and update account groups
        viewModelScope.launch {
            userPreferences.combineAccountsFlow.collect { _ ->
                // Force re-grouping when combine accounts setting changes
                val currentState = _uiState.value
                accountGroupingManager.updateAccountGroups(
                    currentState.oathCredentials, 
                    currentState.pushCredentials
                )
                updateUiStateFromManagers()
            }
        }
        
        // Observe account groups from AccountGroupingManager
        viewModelScope.launch {
            accountGroupingManager.accountGroups.collect { accountGroups ->
                _uiState.update { it.copy(accountGroups = accountGroups) }
            }
        }
        
        // Observe individual state changes
        viewModelScope.launch {
            oathManager.generatedCodes.collect { codes ->
                _uiState.update { it.copy(generatedCodes = codes) }
            }
        }
        
        viewModelScope.launch {
            oathManager.lastAddedOathCredential.collect { credential ->
                _uiState.update { it.copy(lastAddedOathCredential = credential) }
            }
        }
        
        viewModelScope.launch {
            pushManager.lastAddedPushCredential.collect { credential ->
                _uiState.update { it.copy(lastAddedPushCredential = credential) }
            }
        }
        
        viewModelScope.launch {
            oathManager.isLoadingOathCredentials.collect { loading ->
                _uiState.update { it.copy(isLoadingOathCredentials = loading) }
            }
        }
        
        viewModelScope.launch {
            pushManager.isLoadingPushCredentials.collect { loading ->
                _uiState.update { it.copy(isLoadingPushCredentials = loading) }
            }
        }
        
        viewModelScope.launch {
            pushManager.isLoadingNotifications.collect { loading ->
                _uiState.update { it.copy(isLoadingNotifications = loading) }
            }
        }
        
        viewModelScope.launch {
            pushManager.pushNotifications.collect { notifications ->
                _uiState.update { it.copy(pushNotifications = notifications) }
            }
        }
        
        viewModelScope.launch {
            pushManager.pendingNotifications.collect { notifications ->
                _uiState.update { it.copy(pendingNotifications = notifications) }
            }
        }
        
        viewModelScope.launch {
            pushManager.pushNotificationItems.collect { items ->
                _uiState.update { it.copy(pushNotificationItems = items) }
            }
        }
        
        viewModelScope.launch {
            pushManager.pendingNotificationItems.collect { items ->
                _uiState.update { it.copy(pendingNotificationItems = items) }
            }
        }
    }
    
    /**
     * Updates the UI state from all manager states.
     */
    private fun updateUiStateFromManagers() {
        _uiState.update { currentState ->
            currentState.copy(
                oathCredentials = oathManager.oathCredentials.value,
                pushCredentials = pushManager.pushCredentials.value
            )
        }
    }

    /**
     * Loads initial data from all managers.
     */
    private fun loadInitialData() {
        viewModelScope.launch {
            try {
                // Set initial loading state
                _uiState.update { it.copy(isInitialLoading = true) }
                
                // Load all credentials and notifications
                loadOathCredentials()
                loadPushCredentials()
                loadPushNotifications()
                
                // Clear initial loading state once everything is loaded
                _uiState.update { it.copy(isInitialLoading = false) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to initialize", isInitialLoading = false) }
            }
        }
    }

    /**
     * Loads all OATH credentials from the SDK.
     */
    private fun loadOathCredentials() {
        viewModelScope.launch {
            oathManager.loadCredentials().onSuccess {
                oathCredentialsLoaded = true
                _uiState.update { it.copy(error = null) }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to load OATH credentials") }
            }
        }
    }
    
    /**
     * Loads all Push credentials from the SDK.
     */
    private fun loadPushCredentials() {
        viewModelScope.launch {
            pushManager.loadCredentials().onSuccess {
                pushCredentialsLoaded = true
                _uiState.update { it.copy(error = null) }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to load Push credentials") }
            }
        }
    }
    
    /**
     * Loads all push notifications from the SDK.
     */
    private fun loadPushNotifications() {
        viewModelScope.launch {
            pushManager.loadPushNotifications().onSuccess {
                _uiState.update { it.copy(error = null) }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to load push notifications") }
            }
        }
    }


    /**
     * Update the account groups order immediately in the UI state.
     * This provides immediate feedback while the order is being persisted.
     */
    fun updateAccountGroupOrder(newAccountGroups: List<AccountGroup>) {
        accountGroupingManager.updateAccountGroupOrder(newAccountGroups)
        // Also save to preferences asynchronously
        viewModelScope.launch {
            accountGroupingManager.saveAccountOrder(newAccountGroups)
        }
    }

    /**
     * Updates the copy OTP setting
     */
    fun setCopyOtp(enabled: Boolean) {
        viewModelScope.launch {
            diagnosticLogger.d("SettingsScreen: setCopyOtp: $enabled")
            userPreferences.setCopyOtp(enabled)
        }
    }

    /**
     * Updates the tap to reveal setting
     */
    fun setTapToReveal(enabled: Boolean) {
        viewModelScope.launch {
            diagnosticLogger.d("SettingsScreen: setTapToReveal: $enabled")
            userPreferences.setTapToReveal(enabled)
        }
    }

    /**
     * Set whether auto-restore from backup is enabled.
     */
    fun setAutoRestoreFromBackup(enabled: Boolean) {
        viewModelScope.launch {
            userPreferences.setAutoRestoreFromBackup(enabled)
        }
    }

    /**
     * Updates the combine accounts setting
     */
    fun setCombineAccounts(enabled: Boolean) {
        viewModelScope.launch {
            diagnosticLogger.d("SettingsScreen: setCombineAccounts: $enabled")
            userPreferences.setCombineAccounts(enabled)
        }
    }

    /**
     * Updates the diagnostic logging setting
     */
    fun setDiagnosticLogging(enabled: Boolean) {
        viewModelScope.launch {
            diagnosticLogger.d("SettingsScreen: setDiagnosticLogging: $enabled")
            userPreferences.setDiagnosticLogging(enabled)

            // Set the global logger based on the diagnostic logging setting
            Logger.logger = if (enabled) {
                DiagnosticLogger
            } else {
                Logger.STANDARD
            }
        }
    }

    /**
     * Updates the test mode setting
     */
    fun setTestMode(enabled: Boolean) {
        viewModelScope.launch {
            diagnosticLogger.d("SettingsScreen: setTestMode: $enabled")
            userPreferences.setTestMode(enabled)
        }
    }

    /**
     * Updates the theme mode setting
     */
    fun setThemeMode(themeMode: ThemeMode) {
        viewModelScope.launch {
            diagnosticLogger.d("SettingsScreen: setThemeMode: $themeMode")
            userPreferences.setThemeMode(themeMode)
        }
    }

    /**
     * Refreshes all credentials (OATH and Push).
     */
    fun refreshCredentials() {
        viewModelScope.launch {
            try {
                // Set refresh loading state
                _uiState.update { it.copy(isRefreshing = true) }
                
                // Reset loading states before refreshing
                oathCredentialsLoaded = false
                pushCredentialsLoaded = false
                loadOathCredentials()
                loadPushCredentials()
                
                // Clear refresh loading state
                _uiState.update { it.copy(isRefreshing = false) }
            } catch (e: Exception) {
                _uiState.update { it.copy(
                    isRefreshing = false,
                    error = e.message ?: "Failed to refresh credentials"
                ) }
            }
        }
    }

    /**
     * Refreshes push notifications, loading both pending and historical notifications.
     * Call this when entering the notifications screen to ensure all notifications are loaded.
     */
    fun refreshNotifications() {
        viewModelScope.launch {
            try {
                diagnosticLogger.d("Refreshing all notifications")
                pushManager.loadAllPushNotifications().onFailure { e ->
                    _uiState.update { it.copy(error = e.message ?: "Failed to refresh notifications") }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(
                    error = e.message ?: "Failed to refresh notifications"
                ) }
            }
        }
    }

    /**
     * Gets the current device token used for push notifications.
     */
    internal fun getDeviceToken(onTokenReceived: (String?) -> Unit) {
        viewModelScope.launch {
            pushManager.getDeviceToken().onSuccess { token ->
                _uiState.update { it.copy(message = getApplication<Application>().getString(R.string.test_screen_device_token_retrieved)) }
                onTokenReceived(token)
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to get device token") }
                onTokenReceived(null)
            }
        }
    }


    /**
     * Forces a renewal of the Firebase device token.
     */
    internal fun forceDeviceTokenRenew() {
        viewModelScope.launch {
            pushManager.forceDeviceTokenRenew().onSuccess {
                _uiState.update { it.copy(message = getApplication<Application>().getString(R.string.test_screen_device_token_renewed)) }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to renew device token") }
            }
        }
    }
    
    /**
     * Gets a specific push notification item by its ID.
     * This is used to retrieve the notification details for display in the UI.
     */
    fun getNotificationItemById(notificationId: String): PushNotificationItem? {
        return pushManager.getNotificationItemById(notificationId)
    }

    /**
     * Adds an OATH credential from a URI.
     */
    fun addOathCredentialFromUri(uri: String) {
        viewModelScope.launch {
            oathManager.addCredentialFromUri(uri).onSuccess {
                _uiState.update { it.copy(error = null) }
            }.onFailure { e ->
                updateErrorMessage(e, "Failed to add OATH credential")
            }
        }
    }

    /**
     * Adds a Push credential from a URI.
     */
    fun addPushCredentialFromUri(uri: String) {
        viewModelScope.launch {
            pushManager.addCredentialFromUri(uri).onSuccess {
                _uiState.update { it.copy(error = null) }
            }.onFailure { e ->
                updateErrorMessage(e, "Failed to add Push credential")
            }
        }
    }

    /**
     * Adds both OATH and Push credentials from a URI.
     * Ensures that at least the OATH credential is registered even if Push fails.
     */
    fun addMfaCredentialFromUri(uri: String) {
        viewModelScope.launch {
            try {
                // Attempt to add OATH credential first
                oathManager.addCredentialFromUri(uri).onSuccess {
                    _uiState.update { it.copy(error = null) }
                }.onFailure { e ->
                    updateErrorMessage(e, "Failed to add OATH credential")
                    return@launch
                }

                // Attempt to add Push credential
                pushManager.addCredentialFromUri(uri).onSuccess {
                    _uiState.update { it.copy(error = null) }
                }.onFailure { e ->
                    _uiState.update { it.copy(error = "OATH credential added, but failed to add Push credential: ${e.message}") }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Unexpected error while adding MFA credential") }
            }
        }
    }

    /**
     * Removes an OATH credential from the SDK.
     */
    fun removeOathCredential(credentialId: String) {
        viewModelScope.launch {
            oathManager.removeCredential(credentialId).onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to remove OATH credential") }
            }
        }
    }

    /**
     * Removes a Push credential from the SDK.
     */
    fun removePushCredential(credentialId: String) {
        viewModelScope.launch {
            pushManager.removeCredential(credentialId).onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to remove Push credential") }
            }
        }
    }

    /**
     * Updates an OATH credential in the SDK.
     */
    fun updateOathCredential(credential: OathCredential) {
        viewModelScope.launch {
            oathManager.updateCredential(credential).onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to update OATH credential") }
            }
        }
    }

    /**
     * Updates a Push credential in the SDK.
     */
    fun updatePushCredential(credential: PushCredential) {
        viewModelScope.launch {
            pushManager.updateCredential(credential).onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to update Push credential") }
            }
        }
    }

    /**
     * Locks an account by applying the specified policy to all credentials in the account group.
     * 
     * @param accountGroup The account group to lock
     * @param policyName The name of the locking policy to apply
     */
    fun lockAccountGroup(accountGroup: AccountGroup, policyName: String) {
        viewModelScope.launch {
            try {
                // Lock all OATH credentials in the group
                accountGroup.oathCredentials.forEach { credential ->
                    val lockedCredential = credential.copy()
                    lockedCredential.lockCredential(policyName)
                    oathManager.updateCredential(lockedCredential).onFailure { e ->
                        throw e
                    }
                }
                
                // Lock all Push credentials in the group
                accountGroup.pushCredentials.forEach { credential ->
                    val lockedCredential = credential.copy()
                    lockedCredential.lockCredential(policyName)
                    pushManager.updateCredential(lockedCredential).onFailure { e ->
                        throw e
                    }
                }
                
                _uiState.update { 
                    it.copy(message = getApplication<Application>().getString(R.string.test_screen_account_locked_success))
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = e.message ?: "Failed to lock account") 
                }
            }
        }
    }

    /**
     * Unlocks an account by removing the lock from all credentials in the account group.
     * 
     * @param accountGroup The account group to unlock
     */
    fun unlockAccountGroup(accountGroup: AccountGroup) {
        viewModelScope.launch {
            try {
                // Unlock all OATH credentials in the group
                accountGroup.oathCredentials.forEach { credential ->
                    val unlockedCredential = credential.copy()
                    unlockedCredential.unlockCredential()
                    oathManager.updateCredential(unlockedCredential).onFailure { e ->
                        throw e
                    }
                }
                
                // Unlock all Push credentials in the group
                accountGroup.pushCredentials.forEach { credential ->
                    val unlockedCredential = credential.copy()
                    unlockedCredential.unlockCredential()
                    pushManager.updateCredential(unlockedCredential).onFailure { e ->
                        throw e
                    }
                }
                
                // Generate codes immediately for unlocked OATH credentials
                accountGroup.oathCredentials.forEach { credential ->
                    generateCode(credential.id)
                }
                
                _uiState.update { 
                    it.copy(message = getApplication<Application>().getString(R.string.test_screen_account_unlocked_success))
                }
            } catch (e: Exception) {
                _uiState.update { 
                    it.copy(error = e.message ?: "Failed to unlock account") 
                }
            }
        }
    }

    /**
     * Generates a code for a credential.
     */
    fun generateCode(credentialId: String) {
        viewModelScope.launch {
            oathManager.generateCode(credentialId).onFailure { e ->
                if (e is CredentialLockedException) {
                    // Ignore locked credential errors for code generation
                    diagnosticLogger.d("Credential $credentialId is locked, cannot generate code")
                } else {
                    _uiState.update {
                        it.copy(error = e.message ?: "Failed to generate code")
                    }
                }
            }
        }
    }

    /**
     * Approves a push notification.
     */
    fun approveNotification(notificationId: String) {
        viewModelScope.launch {
            pushManager.approveNotification(notificationId).onSuccess { success ->
                if (!success) {
                    _uiState.update { it.copy(error = "Failed to approve notification") }
                }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to approve notification") }
            }
        }
    }

    /**
     * Approves a push notification with a challenge response.
     */
    fun approveChallengeNotification(notificationId: String, challengeResponse: String) {
        viewModelScope.launch {
            pushManager.approveChallengeNotification(notificationId, challengeResponse).onSuccess { success ->
                if (!success) {
                    _uiState.update { it.copy(error = "Failed to approve challenge notification") }
                }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to approve challenge notification") }
            }
        }
    }

    /**
     * Denies a push notification.
     */
    fun denyNotification(notificationId: String) {
        viewModelScope.launch {
            pushManager.denyNotification(notificationId).onSuccess { success ->
                if (!success) {
                    _uiState.update { it.copy(error = "Failed to deny notification") }
                }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to deny notification") }
            }
        }
    }

    /**
     * Cleans up old notifications.
     */
    fun cleanupNotifications() {
        viewModelScope.launch {
            pushManager.cleanupNotifications().onSuccess {
                _uiState.update { it.copy(message = getApplication<Application>().getString(R.string.test_screen_notifications_cleaned_up)) }
            }.onFailure { e ->
                _uiState.update { it.copy(error = e.message ?: "Failed to clean up notifications") }
            }
        }
    }

    /**
     * Sets the error message in the UI state.
     */
    fun setError(errorMessage: String) {
        _uiState.update { it.copy(error = errorMessage) }
    }

    /**
     * Clears the error message in the UI state.
     */
    fun clearError() {
        _uiState.update { it.copy(error = null) }
    }

    /**
     * Sets the message in the UI state.
     */
    fun setMessage(message: String) {
        _uiState.update { it.copy(message = message) }
    }

    /**
     * Clears the message in the UI state.
     */
    fun clearMessage() {
        _uiState.update { it.copy(message = null) }
    }

    /**
     * Clears the last added OATH credential in the UI state.
     */
    fun clearLastAddedOathCredential() {
        oathManager.clearLastAddedCredential()
    }
    
    /**
     * Copies the specified text to the clipboard
     */
    fun copyToClipboard(context: Context, text: String, label: String = "ADB Command") {
        diagnosticLogger.d("Copying code to Clipboard")
        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
        val clip = android.content.ClipData.newPlainText(label, text)
        clipboard.setPrimaryClip(clip)
    }
    
    /**
     * Clears the last added Push credential in the UI state.
     */
    fun clearLastAddedPushCredential() {
        pushManager.clearLastAddedCredential()
    }

    /**
     * Test function: Creates a random OATH account for testing
     */
    fun createRandomOathAccount() {
        viewModelScope.launch {
            try {
                val (uri, message) = testAccountFactory.createRandomOathAccount()
                addOathCredentialFromUri(uri)
                _uiState.update { it.copy(message = message) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to create random OATH account") }
            }
        }
    }
    
    /**
     * Test function: Creates a random PUSH account for testing
     */
    fun createRandomPushAccount() {
        viewModelScope.launch {
            try {
                val (credential, message) = testAccountFactory.createRandomPushCredential()
                
                pushManager.updateCredential(credential).onSuccess {
                    _uiState.update { it.copy(message = message) }
                }.onFailure { e ->
                    _uiState.update { it.copy(error = e.message ?: "Failed to create test push account") }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to create test push account") }
            }
        }
    }

    /**
     * Test function: Creates a random combined OATH + PUSH account for testing
     */
    fun createRandomCombinedMfaAccount() {
        viewModelScope.launch {
            try {
                val (pushCredential, oathCredential, message) = testAccountFactory.createRandomCombinedMfaCredentials()

                // Save both credentials
                var hasError = false
                pushManager.updateCredential(pushCredential).onFailure { e ->
                    _uiState.update { it.copy(error = e.message ?: "Failed to create test push account") }
                    hasError = true
                }
                
                if (!hasError) {
                    oathManager.updateCredential(oathCredential).onSuccess {
                        _uiState.update { it.copy(message = message) }
                    }.onFailure { e ->
                        _uiState.update { it.copy(error = e.message ?: "Failed to create test OATH account") }
                    }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = e.message ?: "Failed to create test combined account") }
            }
        }
    }


    /**
     * Called when the ViewModel is cleared.
     */
    override fun onCleared() {
        super.onCleared()
        
        viewModelScope.launch {
            try {
                // Close managers to release resources
                oathManager.close()
                pushManager.close()
            } catch (e: Exception) {
                // Log any errors during cleanup
                diagnosticLogger.e("Error closing managers", e)
            }
        }
    }

    /**
     * Gets the list of OATH backup files.
     * Returns a list of backup file info (name, size, timestamp).
     */
    fun getOathBackupFiles(callback: (List<BackupFileInfo>) -> Unit) {
        viewModelScope.launch {
            try {
                val backups = oathManager.getBackupFiles()
                callback(backups)
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to get OATH backups: ${e.message}") }
                callback(emptyList())
            }
        }
    }
    
    /**
     * Gets the list of PUSH backup files.
     * Returns a list of backup file info (name, size, timestamp).
     */
    fun getPushBackupFiles(callback: (List<BackupFileInfo>) -> Unit) {
        viewModelScope.launch {
            try {
                val backups = pushManager.getBackupFiles()
                callback(backups)
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to get PUSH backups: ${e.message}") }
                callback(emptyList())
            }
        }
    }
    
    /**
     * Restores OATH database from the latest backup.
     */
    fun restoreOathFromBackup() {
        viewModelScope.launch {
            try {
                val success = oathManager.restoreFromBackup(getApplication())
                if (success) {
                    _uiState.update { it.copy(message = "OATH database restored successfully") }
                    // Reload credentials after restoration
                    loadOathCredentials()
                } else {
                    _uiState.update { it.copy(error = "No OATH backup available to restore") }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to restore OATH backup: ${e.message}") }
            }
        }
    }
    
    /**
     * Restores PUSH database from the latest backup.
     */
    fun restorePushFromBackup() {
        viewModelScope.launch {
            try {
                val success = pushManager.restoreFromBackup(getApplication())
                if (success) {
                    _uiState.update { it.copy(message = "PUSH database restored successfully") }
                    // Reload credentials after restoration
                    loadPushCredentials()
                } else {
                    _uiState.update { it.copy(error = "No PUSH backup available to restore") }
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to restore PUSH backup: ${e.message}") }
            }
        }
    }
    
    /**
     * Simulates making the OATH database read-only for testing error handling.
     */
    fun simulateOathDatabaseReadOnly() {
        viewModelScope.launch {
            try {
                oathManager.makeDatabaseReadOnly()
                _uiState.update { 
                    it.copy(message = "OATH database is now read-only. Restart app to test error handling.") 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to make OATH DB read-only: ${e.message}") }
            }
        }
    }
    
    /**
     * Simulates corrupting the OATH database for testing error handling.
     */
    fun simulateOathDatabaseCorruption() {
        viewModelScope.launch {
            try {
                oathManager.corruptDatabase()
                _uiState.update { 
                    it.copy(message = "OATH database corrupted. Restart app to test recovery.") 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to corrupt OATH database: ${e.message}") }
            }
        }
    }
    
    /**
     * Simulates making the PUSH database read-only for testing error handling.
     */
    fun simulatePushDatabaseReadOnly() {
        viewModelScope.launch {
            try {
                pushManager.makeDatabaseReadOnly()
                _uiState.update { 
                    it.copy(message = "Push database is now read-only. Restart app to test error handling.") 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to make Push DB read-only: ${e.message}") }
            }
        }
    }
    
    /**
     * Simulates corrupting the PUSH database for testing error handling.
     */
    fun simulatePushDatabaseCorruption() {
        viewModelScope.launch {
            try {
                pushManager.corruptDatabase()
                _uiState.update { 
                    it.copy(message = "PUSH database corrupted. Restart app to test error handling.") 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to corrupt PUSH DB: ${e.message}") }
            }
        }
    }
    
    /**
     * Clears all backup files for both OATH and PUSH.
     */
    fun clearAllBackups() {
        viewModelScope.launch {
            try {
                val oathCleared = oathManager.clearBackups()
                val pushCleared = pushManager.clearBackups()
                val total = oathCleared + pushCleared
                _uiState.update { 
                    it.copy(message = "Cleared $total backup file(s) ($oathCleared OATH, $pushCleared PUSH)") 
                }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to clear backups: ${e.message}") }
            }
        }
    }
    
    /**
     * Creates manual backups for both OATH and PUSH databases.
     */
    fun createManualBackups() {
        viewModelScope.launch {
            try {
                var oathBackupCount = 0
                var pushBackupCount = 0
                
                // Get current backup counts
                val oathInfo = oathManager.getDatabaseInfo()
                val pushInfo = pushManager.getDatabaseInfo()
                
                val beforeOathCount = oathInfo.backupCount
                val beforePushCount = pushInfo.backupCount
                
                // Create OATH backup
                try {
                    oathManager.createManualBackup()
                    val afterOathInfo = oathManager.getDatabaseInfo()
                    oathBackupCount = afterOathInfo.backupCount - beforeOathCount
                } catch (e: Exception) {
                    diagnosticLogger.w("Failed to create OATH backup: ${e.message}")
                }
                
                // Create PUSH backup
                try {
                    pushManager.createManualBackup()
                    val afterPushInfo = pushManager.getDatabaseInfo()
                    pushBackupCount = afterPushInfo.backupCount - beforePushCount
                } catch (e: Exception) {
                    diagnosticLogger.w("Failed to create PUSH backup: ${e.message}")
                }
                
                val message = buildString {
                    append("Manual backup created successfully!")
                    if (oathBackupCount > 0 || pushBackupCount > 0) {
                        append(" (")
                        if (oathBackupCount > 0) append("OATH: +$oathBackupCount")
                        if (oathBackupCount > 0 && pushBackupCount > 0) append(", ")
                        if (pushBackupCount > 0) append("PUSH: +$pushBackupCount")
                        append(")")
                    }
                }
                
                _uiState.update { it.copy(message = message) }
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to create backups: ${e.message}") }
            }
        }
    }
    
    /**
     * Gets database information for display.
     */
    fun getDatabaseInfo(callback: (DatabaseInfo) -> Unit) {
        viewModelScope.launch {
            try {
                val oathInfo = oathManager.getDatabaseInfo()
                val pushInfo = pushManager.getDatabaseInfo()
                
                val info = DatabaseInfo(
                    oathDbPath = oathInfo.path,
                    oathDbSize = oathInfo.size,
                    oathBackupCount = oathInfo.backupCount,
                    pushDbPath = pushInfo.path,
                    pushDbSize = pushInfo.size,
                    pushBackupCount = pushInfo.backupCount
                )
                callback(info)
            } catch (e: Exception) {
                _uiState.update { it.copy(error = "Failed to get database info: ${e.message}") }
            }
        }
    }
    
    /**
     * Sets the initialization error state.
     */
    fun setInitializationError(error: InitializationError) {
        _uiState.update { it.copy(initializationError = error) }
    }
    
    /**
     * Attempts to restore from backup.
     */
    suspend fun attemptRestoreFromBackup(): Result<Boolean> {
        val initError = _uiState.value.initializationError ?: return Result.failure(
            IllegalStateException("No initialization error present")
        )
        
        return try {
            var oathRestored = true
            var pushRestored = true
            
            // Check which components need restoration based on error list
            val hasOathError = initError.errors.any { it.component == "OATH" }
            val hasPushError = initError.errors.any { it.component == "Push" }
            
            // Restore OATH if it failed
            if (hasOathError) {
                oathRestored = oathManager.restoreFromBackup(getApplication())
                diagnosticLogger.i("OATH restore result: $oathRestored")
            }
            
            // Restore Push if it failed
            if (hasPushError) {
                pushRestored = pushManager.restoreFromBackup(getApplication())
                diagnosticLogger.i("Push restore result: $pushRestored")
            }
            
            val success = oathRestored && pushRestored
            if (success) {
                diagnosticLogger.i("Successfully restored from backup")
                Result.success(true)
            } else {
                val failedComponents = mutableListOf<String>()
                if (hasOathError && !oathRestored) failedComponents.add("OATH")
                if (hasPushError && !pushRestored) failedComponents.add("Push")
                Result.failure(Exception("Backup restoration failed for: ${failedComponents.joinToString(", ")}"))
            }
        } catch (e: Exception) {
            diagnosticLogger.e("Error during backup restoration", e)
            Result.failure(e)
        }
    }
    
    /**
     * Enables destructive recovery and triggers app restart.
     * This will delete corrupted databases and start fresh.
     */
    suspend fun enableDestructiveRecoveryAndRestart(): Result<Unit> {
        return try {
            // Enable destructive recovery in settings
            userPreferences.setDestructiveRecovery(true)
            diagnosticLogger.i("Destructive recovery enabled - app will restart")
            Result.success(Unit)
        } catch (e: Exception) {
            diagnosticLogger.e("Error enabling destructive recovery", e)
            Result.failure(e)
        }
    }
    
    /**
     * Sets the destructive recovery setting.
     */
    fun setDestructiveRecovery(enabled: Boolean) {
        viewModelScope.launch {
            userPreferences.setDestructiveRecovery(enabled)
        }
    }

    /**
     * Updates the error message in the UI state.
     */
    private fun updateErrorMessage(throwable: Throwable, message: String) {
        val errorMessage = when {
            throwable is DuplicateCredentialException || throwable.cause is DuplicateCredentialException -> {
                val dupException = (throwable as? DuplicateCredentialException)
                    ?: (throwable.cause as DuplicateCredentialException)
                "Account already exists: ${dupException.issuer} - ${dupException.accountName}"
            }

            else -> throwable.message ?: message
        }
        _uiState.update { it.copy(error = errorMessage) }
    }
}

/**
 * Data class representing the UI state of the Authenticator app.
 */
data class AuthenticatorUiState(
    val oathCredentials: List<OathCredential> = emptyList(),
    val pushCredentials: List<PushCredential> = emptyList(),
    val accountGroups: List<AccountGroup> = emptyList(),
    val generatedCodes: Map<String, OathCodeInfo> = emptyMap(),
    val pushNotifications: List<PushNotification> = emptyList(),
    val pendingNotifications: List<PushNotification> = emptyList(),
    val pushNotificationItems: List<PushNotificationItem> = emptyList(),
    val pendingNotificationItems: List<PushNotificationItem> = emptyList(),
    val lastAddedOathCredential: OathCredential? = null,
    val lastAddedPushCredential: PushCredential? = null,
    val error: String? = null,
    val message: String? = null,
    val initializationError: InitializationError? = null,
    // Loading states for better UX
    val isInitialLoading: Boolean = false,
    val isRefreshing: Boolean = false,
    val isLoadingOathCredentials: Boolean = false,
    val isLoadingPushCredentials: Boolean = false,
    val isLoadingNotifications: Boolean = false
)
