/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.data

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.pingidentity.authenticatorapp.managers.JourneyManager
import com.pingidentity.authenticatorapp.managers.OathManager
import com.pingidentity.authenticatorapp.managers.PushManager
import com.pingidentity.journey.callback.HiddenValueCallback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.journey.user
import com.pingidentity.mfa.commons.UriScheme
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.utils.Result
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.jsonPrimitive

/* Constant for the default Journey name used for MFA registration.
 * This should match the name of the Journey configured in the PingAM / PingAIC Identity platforms.
 */
private const val AUTHENTICATOR_AUTH = "Authenticator-Authn"

/* Constant for the ID of the HiddenValueCallback used for MFA device registration.
 * This should match the ID for the callbacks created by Push Registration, Oath Registration,
 * and Combined MFA Registration nodes.
 */
private const val MFA_CALLBACK_ID = "mfaDeviceRegistration"

/**
 * ViewModel for handling Journey-based authentication and credential enrollment
 */
class LoginViewModel(
    application: Application,
    private val journeyManager: JourneyManager,
    private val oathManager: OathManager,
    private val pushManager: PushManager
) : AndroidViewModel(application), ViewModelProvider.Factory {

    private val diagnosticLogger = DiagnosticLogger

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState.asStateFlow()
    
    // Track credentials added during this Journey session
    private val journeyCredentialIds = mutableSetOf<String>()
    
    init {
        // Observe Journey manager state and update UI accordingly
        setupStateFlows()
    }
    
    /**
     * Sets up state flows to observe Journey manager state changes.
     */
    private fun setupStateFlows() {
        viewModelScope.launch {
            journeyManager.currentNode.collect { node ->
                _uiState.value = _uiState.value.copy(currentNode = node)
                // Handle MFA registration and polling logic when node changes
                if (node is ContinueNode) {
                    handleContinueNode(node)
                }
            }
        }
        
        viewModelScope.launch {
            journeyManager.isLoading.collect { isLoading ->
                _uiState.value = _uiState.value.copy(isLoading = isLoading)
            }
        }
        
        viewModelScope.launch {
            journeyManager.isPolling.collect { isPolling ->
                _uiState.value = _uiState.value.copy(isPolling = isPolling)
            }
        }
        
        viewModelScope.launch {
            journeyManager.isSuccess.collect { isSuccess ->
                _uiState.value = _uiState.value.copy(isSuccess = isSuccess)
                if (isSuccess) {
                    handleSuccessNode()
                }
            }
        }
        
        viewModelScope.launch {
            journeyManager.error.collect { error ->
                _uiState.value = _uiState.value.copy(error = error)
            }
        }
        
        viewModelScope.launch {
            journeyManager.message.collect { message ->
                _uiState.value = _uiState.value.copy(message = message)
            }
        }
    }
    
    /**
     * Starts the journey authentication flow
     */
    fun startJourney(journeyName: String = AUTHENTICATOR_AUTH) {
        viewModelScope.launch {
            journeyManager.startJourney(journeyName)
        }
    }
    
    /**
     * Continues the journey flow with the current node
     */
    fun nextStep() {
        viewModelScope.launch {
            journeyManager.continueJourney()
        }
    }
    
    /**
     * Refreshes the current node state (useful when callbacks are updated)
     */
    fun refreshNode() {
        _uiState.value = _uiState.value.copy(currentNode = journeyManager.currentNode.value)
    }
    
    /**
     * Handles continue nodes, processing callbacks and polling
     */
    private suspend fun handleContinueNode(node: ContinueNode) {
        diagnosticLogger.d("Processing continue node with ${node.callbacks.size} callbacks")
        
        // Check for MFA registration callback first (highest priority)
        val hiddenValueCallback = node.callbacks
            .filterIsInstance<HiddenValueCallback>()
            .find { it.id == MFA_CALLBACK_ID }
            
        if (hiddenValueCallback != null && hiddenValueCallback.value.isNotEmpty()) {
            diagnosticLogger.d("Found MFA device registration URI - processing immediately")
            // Set MFA registration state to hide callbacks and show loading message
            _uiState.value = _uiState.value.copy(
                isMfaRegistering = true,
                message = "Registering MFA credentials..."
            )
            
            handleMfaRegistration(hiddenValueCallback.value)
            return
        }
        
        // Check for polling wait callback 
        val pollingCallback = journeyManager.getPollingCallback(node)
        if (pollingCallback != null) {
            diagnosticLogger.d("Polling callback found - waiting for credential registration to complete")
            val message = pollingCallback.message.ifEmpty { "Waiting for credential registration..." }
            journeyManager.setPollingState(true, message)
            
            // Instead of using the server's wait time, use a shorter interval to check more frequently
            // for credential registration completion
            diagnosticLogger.d("Using shorter polling interval (3s) instead of server suggested ${pollingCallback.waitTime}ms")
            delay(3000L)
            
            journeyManager.setPollingState(false)
            journeyManager.continueJourney()
            return
        }
    }
    
    /**
     * Handles MFA credential registration from URI
     */
    private suspend fun handleMfaRegistration(uri: String) {
        diagnosticLogger.d("Processing MFA registration URI: ${maskUri(uri)}")
        
        try {
            when {
                uri.startsWith(UriScheme.OTPAUTH.value) -> {
                    // OATH credential registration
                    val result = oathManager.addCredentialFromUri(uri)
                    result.onSuccess { credential ->
                        diagnosticLogger.d("Successfully added OATH credential: ${credential.issuer}/${credential.accountName}")
                        journeyCredentialIds.add(credential.id) // Track this credential as Journey-registered
                        journeyManager.setMessage("OATH credential registered - continuing journey...")
                        // Clear MFA registration state and continue the journey
                        _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                        journeyManager.continueJourney()
                    }.onFailure { exception ->
                        diagnosticLogger.e("Failed to add OATH credential", exception)
                        // Clear MFA registration state on failure
                        _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                        journeyManager.setError("Failed to register OATH credential: ${exception.message}")
                    }
                }
                
                uri.startsWith(UriScheme.PUSHAUTH.value) -> {
                    // Push credential registration
                    val result = pushManager.addCredentialFromUri(uri)
                    result.onSuccess { credential ->
                        diagnosticLogger.d("Successfully added Push credential: ${credential.issuer}/${credential.accountName}")
                        journeyCredentialIds.add(credential.id) // Track this credential as Journey-registered
                        journeyManager.setMessage("Push credential registered - continuing journey...")
                        // Clear MFA registration state and continue the journey
                        _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                        journeyManager.continueJourney()
                    }.onFailure { exception ->
                        diagnosticLogger.e("Failed to add Push credential", exception)
                        // Clear MFA registration state on failure
                        _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                        journeyManager.setError("Failed to register Push credential: ${exception.message}")
                    }
                }
                
                uri.startsWith(UriScheme.MFAUTH.value) -> {
                    // Combined MFA registration - try both
                    journeyManager.setMessage("Registering combined MFA credentials...")
                    
                    var oathSuccess = false
                    var pushSuccess = false
                    var lastError: Throwable? = null
                    
                    // Try OATH first
                    val oathResult = oathManager.addCredentialFromUri(uri)
                    oathResult.onSuccess { credential ->
                        oathSuccess = true
                        journeyCredentialIds.add(credential.id) // Track this credential as Journey-registered
                        diagnosticLogger.d("Successfully added OATH credential from combined URI")
                    }.onFailure { 
                        lastError = it
                        diagnosticLogger.w("Failed to add OATH credential from combined URI", it)
                    }
                    
                    // Try Push second
                    val pushResult = pushManager.addCredentialFromUri(uri)
                    pushResult.onSuccess { credential ->
                        pushSuccess = true
                        journeyCredentialIds.add(credential.id) // Track this credential as Journey-registered
                        diagnosticLogger.d("Successfully added Push credential from combined URI")
                    }.onFailure { 
                        lastError = it
                        diagnosticLogger.w("Failed to add Push credential from combined URI", it)
                    }
                    
                    // Determine final result
                    when {
                        oathSuccess && pushSuccess -> {
                            diagnosticLogger.d("Both OATH and Push credentials registered successfully")
                            journeyManager.setMessage("Both credentials registered - continuing journey...")
                            // Clear MFA registration state and continue the journey
                            _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                            journeyManager.continueJourney()
                        }
                        oathSuccess || pushSuccess -> {
                            val type = if (oathSuccess) "OATH" else "Push"
                            diagnosticLogger.d("$type credential registered successfully (partial success)")
                            journeyManager.setMessage("$type credential registered - continuing journey...")
                            // Clear MFA registration state and continue the journey
                            _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                            journeyManager.continueJourney()
                        }
                        else -> {
                            // Clear MFA registration state on failure
                            _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                            journeyManager.setError("Failed to register MFA credentials: ${lastError?.message ?: "Unknown error"}")
                        }
                    }
                }
                
                else -> {
                    diagnosticLogger.w("Unsupported URI scheme: $uri")
                    // Clear MFA registration state on unsupported URI
                    _uiState.value = _uiState.value.copy(isMfaRegistering = false)
                    journeyManager.setError("Unsupported credential type")
                }
            }
        } catch (e: Exception) {
            diagnosticLogger.e("Unexpected error during MFA registration", e)
            // Clear MFA registration state on unexpected error
            _uiState.value = _uiState.value.copy(isMfaRegistering = false)
            journeyManager.setError("Unexpected error: ${e.message}")
        }
    }
    
    /**
     * Handles successful authentication
     */
    private fun handleSuccessNode() {
        diagnosticLogger.d("Journey completed successfully")
        
        // Associate userId with Journey-registered credentials
        viewModelScope.launch {
            try {
                associateUserWithCredentials()
            } catch (e: Exception) {
                diagnosticLogger.w("Failed to associate userId with Journey-registered credentials", e)
                // Don't fail the whole authentication flow for this issue
            }
        }
    }

    /**
     * Logs out the current user (if any)
     */
    fun logout() {
        viewModelScope.launch {
            journeyManager.logout()
        }
    }
    

    /**
     * Associate credentials registered during this Journey with the authenticated user
     * by setting their userId to enable user session functionality.
     */
    private suspend fun associateUserWithCredentials() {
        try {
            // If no credentials were registered during this Journey, nothing to do
            if (journeyCredentialIds.isEmpty()) {
                diagnosticLogger.d("No credentials registered during this Journey - skipping user session association")
                return
            }

            // Get the user ID from the Journey session
            val journey = journeyManager.getJourneyClient()
            if (journey == null) {
                diagnosticLogger.w("No Journey client available - cannot mark credentials as user session enabled")
                return
            }
            
            val user = journey.user()
            if (user == null) {
                diagnosticLogger.w("No user available from Journey - cannot mark credentials as user session enabled")
                return
            }
            
            val userInfo = user.userinfo(cache = false)
            val userId = when (userInfo) {
                is Result.Success -> {
                    val sub = userInfo.value["sub"]?.jsonPrimitive?.content
                    if (sub == null) {
                        diagnosticLogger.w("No 'sub' field in user info - cannot get user ID")
                        return
                    }
                    sub
                }
                is Result.Failure -> {
                    diagnosticLogger.w("Failed to get user info: ${userInfo.value}")
                    return
                }
            }

            // Get all credentials and filter to only those registered during this Journey session
            val oathCredentialsResult = oathManager.loadCredentials()
            val pushCredentialsResult = pushManager.loadCredentials()
            
            val oathCredentials = oathCredentialsResult.getOrNull() ?: emptyList()
            val pushCredentials = pushCredentialsResult.getOrNull() ?: emptyList()
            
            // Filter to only credentials that were registered during this Journey session and have no userId set
            val oathCredentialsToUpdate = oathCredentials.filter { it.id in journeyCredentialIds && it.userId == null }
            val pushCredentialsToUpdate = pushCredentials.filter { it.id in journeyCredentialIds && it.userId == null }

            // If no credentials need updating, nothing to do
            if (oathCredentialsToUpdate.isEmpty() && pushCredentialsToUpdate.isEmpty()) {
                diagnosticLogger.d("No Journey-registered credentials found that need user session association")
                return
            }

            // Update each credential to set the userId
            diagnosticLogger.d("Found ${oathCredentialsToUpdate.size} OATH credentials and ${pushCredentialsToUpdate.size} Push credentials to update")
            diagnosticLogger.d("Associating userId [$userId] with Journey-registered credentials")

            // Update OATH credentials
            oathCredentialsToUpdate.forEach { credential ->
                val updatedCredential = credential.copy(userId = userId)
                val result = oathManager.updateCredential(updatedCredential)
                result.onSuccess {
                    diagnosticLogger.d("Updated OATH credential ${credential.id} for user session")
                }.onFailure { 
                    diagnosticLogger.w("Failed to update OATH credential ${credential.id}", it)
                }
            }
            
            // Update Push credentials  
            pushCredentialsToUpdate.forEach { credential ->
                val updatedCredential = credential.copy(userId = userId)
                val result = pushManager.updateCredential(updatedCredential)
                result.onSuccess {
                    diagnosticLogger.d("Updated Push credential ${credential.id} for user session")
                }.onFailure { 
                    diagnosticLogger.w("Failed to update Push credential ${credential.id}", it)
                }
            }
            
            val totalUpdated = oathCredentialsToUpdate.size + pushCredentialsToUpdate.size
            if (totalUpdated > 0) {
                diagnosticLogger.d("Successfully associated $totalUpdated credentials with the user")
            }
        } catch (e: Exception) {
            diagnosticLogger.e("Unexpected error associating user with Journey-registered credentials", e)
            throw e
        }
    }

    /**
     * Resets the login state
     */
    fun reset() {
        journeyCredentialIds.clear() // Clear tracked credential IDs
        journeyManager.reset()
        _uiState.value = LoginUiState()
    }
    
    /**
     * Called when the ViewModel is being cleared, typically when the owner activity/fragment
     * is destroyed. This ensures proper cleanup of resources.
     */
    override fun onCleared() {
        super.onCleared()

        try {
            // Close Journey manager to release resources, let other managers be handled
            // by Authenticator ViewModel
            journeyManager.close()
            diagnosticLogger.d("LoginViewModel cleared and resources released")
        } catch (e: Exception) {
            // Log any errors during cleanup
            diagnosticLogger.e("Error closing manager", e)
        }
    }
    
    /**
     * Masks sensitive information in URIs for logging
     */
    private fun maskUri(uri: String): String {
        return uri.replace(Regex("secret=[^&]*"), "secret=*****")
    }
}

/**
 * UI state for the login screen
 */
data class LoginUiState(
    val isLoading: Boolean = false,
    val isPolling: Boolean = false,
    val isSuccess: Boolean = false,
    val error: String? = null,
    val message: String? = null,
    val currentNode: Node? = null,
    val isMfaRegistering: Boolean = false
)
