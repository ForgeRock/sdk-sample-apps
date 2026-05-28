/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.managers

import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.journey.Journey
import com.pingidentity.journey.callback.PollingWaitCallback
import com.pingidentity.journey.plugin.callbacks
import com.pingidentity.journey.start
import com.pingidentity.journey.user
import com.pingidentity.orchestrate.ContinueNode
import com.pingidentity.orchestrate.ErrorNode
import com.pingidentity.orchestrate.FailureNode
import com.pingidentity.orchestrate.Node
import com.pingidentity.orchestrate.SuccessNode
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext

/**
 * Manager class for handling Journey-based authentication operations.
 * Encapsulates Journey-specific business logic and state management.
 *
 * @param journey The Journey client instance
 * @param diagnosticLogger DiagnosticLogger for logging
 */
class JourneyManager(
    private var journey: Journey? = null,
    private val diagnosticLogger: DiagnosticLogger
) {
    
    private val _currentNode = MutableStateFlow<Node?>(null)
    val currentNode: StateFlow<Node?> = _currentNode.asStateFlow()
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()
    
    private val _isPolling = MutableStateFlow(false)
    val isPolling: StateFlow<Boolean> = _isPolling.asStateFlow()
    
    private val _isSuccess = MutableStateFlow(false)
    val isSuccess: StateFlow<Boolean> = _isSuccess.asStateFlow()
    
    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()
    
    private val _message = MutableStateFlow<String?>(null)
    val message: StateFlow<String?> = _message.asStateFlow()

    /**
     * Sets the Journey client instance.
     */
    fun setClient(client: Journey) {
        this.journey = client
    }

    /**
     * Starts a Journey authentication flow.
     */
    suspend fun startJourney(journeyName: String): Result<Node> {
        val client = journey ?: return Result.failure(Exception("Journey client not initialized"))
        
        return try {
            _isLoading.value = true
            _error.value = null
            _isSuccess.value = false
            _message.value = "Starting authentication..."
            
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Starting journey: $journeyName")
                client.start(journeyName)
            }
            
            _currentNode.value = result
            updateStateFromNode(result)
            
            Result.success(result)
        } catch (e: Exception) {
            diagnosticLogger.e("Failed to start journey", e)
            _isLoading.value = false
            _error.value = "Failed to start authentication: ${e.message}"
            Result.failure(e)
        }
    }

    /**
     * Continues the Journey flow with the current node.
     */
    suspend fun continueJourney(): Result<Node> {
        val currentNode = _currentNode.value
        if (currentNode !is ContinueNode) {
            return Result.failure(Exception("Cannot continue - current node is not a continue node"))
        }
        
        return try {
            _isLoading.value = true
            
            val result = withContext(Dispatchers.IO) {
                diagnosticLogger.d("Continuing journey with ${currentNode.callbacks.size} callbacks")
                currentNode.next()
            }
            
            _currentNode.value = result
            updateStateFromNode(result)
            
            Result.success(result)
        } catch (e: Exception) {
            diagnosticLogger.e("Failed to continue journey", e)
            _isLoading.value = false
            _error.value = "Authentication failed: ${e.message}"
            Result.failure(e)
        }
    }

    /**
     * Gets the polling callback from the current node if it exists.
     */
    fun getPollingCallback(node: Node): PollingWaitCallback? {
        return if (node is ContinueNode) {
            node.callbacks.find { it is PollingWaitCallback } as? PollingWaitCallback
        } else null
    }

    /**
     * Sets polling state.
     */
    fun setPollingState(isPolling: Boolean, message: String? = null) {
        _isPolling.value = isPolling
        if (message != null) {
            _message.value = message
        }
    }

    /**
     * Gets the Journey instance for external use (e.g., by LoginViewModel for user operations).
     */
    fun getJourneyClient(): Journey? {
        return journey
    }

    /**
     * Logs out the current user.
     */
    suspend fun logout(): Result<Unit> {
        val client = journey ?: return Result.failure(Exception("Journey client not initialized"))
        
        return try {
            val user = withContext(Dispatchers.IO) {
                client.user()
            }
            
            if (user != null) {
                withContext(Dispatchers.IO) {
                    user.logout()
                }
                diagnosticLogger.d("User logged out successfully")
                Result.success(Unit)
            } else {
                diagnosticLogger.d("No user to log out")
                Result.success(Unit)
            }
        } catch (e: Exception) {
            diagnosticLogger.e("Failed to log out user", e)
            Result.failure(e)
        }
    }

    /**
     * Resets the Journey state.
     */
    fun reset() {
        _currentNode.value = null
        _isLoading.value = false
        _isPolling.value = false
        _isSuccess.value = false
        _error.value = null
        _message.value = null
    }

    /**
     * Sets error message.
     */
    fun setError(errorMessage: String) {
        _error.value = errorMessage
        _isLoading.value = false
        _isPolling.value = false
    }

    /**
     * Sets message.
     */
    fun setMessage(message: String) {
        _message.value = message
    }

    /**
     * Updates internal state based on the current node type.
     */
    private fun updateStateFromNode(node: Node) {
        diagnosticLogger.d("Handling node: ${node.javaClass.simpleName}")
        
        when (node) {
            is ContinueNode -> {
                _isLoading.value = false
                _message.value = "Please provide required information"
            }
            is SuccessNode -> {
                diagnosticLogger.d("Journey completed successfully")
                _isLoading.value = false
                _isSuccess.value = true
                _message.value = "Authentication completed successfully"
            }
            is ErrorNode -> {
                diagnosticLogger.w("Journey failed with error: ${node.message}")
                _isLoading.value = false
                _error.value = "Authentication error: ${node.message}"
            }
            is FailureNode -> {
                diagnosticLogger.e("Journey failed with exception", node.cause)
                _isLoading.value = false
                _error.value = "Authentication failed: ${node.cause.message}"
            }
        }
    }

    /**
     * Closes the Journey client and releases resources.
     * This should be called when the associated ViewModel is cleared
     * or when the application no longer needs the Journey client.
     * It ensures proper cleanup of resources and prevents memory leaks.
     */
    fun close() {
        try {
            // Journey doesn't require explicit closing, but we should
            // release our reference to allow proper garbage collection
            diagnosticLogger.d("Closing Journey client and releasing resources")
            journey = null
        } catch (e: Exception) {
            diagnosticLogger.e("Error closing Journey client", e)
        }
    }
}