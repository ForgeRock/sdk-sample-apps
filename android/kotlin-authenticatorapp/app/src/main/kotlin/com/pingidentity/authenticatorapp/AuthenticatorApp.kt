/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp

import android.app.Application
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.data.UserPreferences
import com.pingidentity.journey.Journey
import com.pingidentity.journey.module.Oidc
import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.mfa.oath.OathClient
import com.pingidentity.mfa.oath.storage.SQLOathStorage
import com.pingidentity.mfa.push.PushClient
import com.pingidentity.mfa.push.storage.SQLPushStorage
import com.pingidentity.storage.sqlite.passphrase.KeyStorePassphraseProvider
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

/**
 * Main application class for the Authenticator app.
 * Initializes the Push and OATH MFA clients on application startup and provide access to them throughout the app.
 * It also allow the clients to be accessed in background services or other components that require MFA functionality.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class AuthenticatorApp : Application() {
    @Volatile
    private lateinit var pushClient: PushClient

    @Volatile
    private lateinit var oathClient: OathClient

    @Volatile
    private lateinit var journey: Journey

    @Volatile
    private lateinit var oathStorage: SQLOathStorage

    @Volatile
    private lateinit var pushStorage: SQLPushStorage

    private val pushClientDeferred = CompletableDeferred<PushClient>()
    private val oathClientDeferred = CompletableDeferred<OathClient>()
    private val journeyDeferred = CompletableDeferred<Journey>()
    private val oathStorageDeferred = CompletableDeferred<SQLOathStorage>()
    private val pushStorageDeferred = CompletableDeferred<SQLPushStorage>()
    
    // Track initialization errors
    private val initializationErrors = mutableListOf<com.pingidentity.authenticatorapp.data.ComponentError>()

    override fun onCreate() {
        super.onCreate()
        
        // Initialize diagnostic logging if enabled
        val userPreferences = UserPreferences(this)
        val diagnosticLogger = if (userPreferences.isDiagnosticLoggingEnabled()) {
            DiagnosticLogger
        } else {
            Logger.STANDARD
        }
        
        // Set the global logger
        Logger.logger = diagnosticLogger
        
        // Log initial startup
        if (userPreferences.isDiagnosticLoggingEnabled()) {
            diagnosticLogger.i("AuthenticatorApp: Diagnostic logging enabled")
            diagnosticLogger.i("AuthenticatorApp: Starting SDK initialization")
        }
        
        CoroutineScope(Dispatchers.Default).launch {
            // TODO: Update with your Journey configuration
            // Initialize Journey SDK
            try {
                journey = Journey {
                    logger = diagnosticLogger
                    serverUrl = "<YOUR_SERVER_URL>" // e.g. https://openam.example.com/am
                    realm = "<YOUR_REALM>" // e.g. /alpha
                    cookie = "<YOUR_COOKIE>" // e.g. iPlanetDirectoryPro
                    // Oidc as module
                    module(Oidc) {
                        clientId = "<YOUR_CLIENT_ID>" // e.g. myclient
                        discoveryEndpoint = "<YOUR_DISCOVERY_ENDPOINT>" // e.g. https://openam.example.com/am/oauth2/.well-known/openid-configuration?realm=/alpha
                        // Scopes to request - adjust as needed
                        scopes = mutableSetOf("openid", "email", "address", "profile", "phone")
                        redirectUri = "<YOUR_REDIRECT_URI>" // e.g. myapp://callback
                    }
                }
                journeyDeferred.complete(journey)
                diagnosticLogger.i("AuthenticatorApp: Journey client initialized")
            } catch (e: Exception) {
                diagnosticLogger.e("AuthenticatorApp: Failed to initialize Journey", e)
                journeyDeferred.completeExceptionally(e)
            }

            // Get destructive recovery setting
            val destructiveRecoveryEnabled = userPreferences.isDestructiveRecoveryEnabled()
            diagnosticLogger.i("AuthenticatorApp: Destructive recovery enabled: $destructiveRecoveryEnabled")
            
            // Get auto-restore from backup setting
            val autoRestoreEnabled = userPreferences.isAutoRestoreFromBackupEnabled()
            diagnosticLogger.i("AuthenticatorApp: Auto-restore from backup enabled: $autoRestoreEnabled")

            // Create OATH storage instance
            try {
                oathStorage = createOathStorage(
                    context = this@AuthenticatorApp,
                    autoRestoreFromBackup = autoRestoreEnabled,
                    allowDestructiveRecovery = destructiveRecoveryEnabled,
                    logger = diagnosticLogger
                )
                oathStorageDeferred.complete(oathStorage)
                diagnosticLogger.i("AuthenticatorApp: OATH storage created")
            } catch (e: Exception) {
                diagnosticLogger.e("AuthenticatorApp: Failed to create OATH storage", e)
                synchronized(initializationErrors) {
                    initializationErrors.add(com.pingidentity.authenticatorapp.data.ComponentError("OATH", e))
                }
                oathStorageDeferred.completeExceptionally(e)
            }

            // Create Push storage instance
            try {
                pushStorage = createPushStorage(
                    context = this@AuthenticatorApp,
                    autoRestoreFromBackup = autoRestoreEnabled,
                    allowDestructiveRecovery = destructiveRecoveryEnabled,
                    logger = diagnosticLogger
                )
                pushStorageDeferred.complete(pushStorage)
                diagnosticLogger.i("AuthenticatorApp: Push storage created")
            } catch (e: Exception) {
                diagnosticLogger.e("AuthenticatorApp: Failed to create Push storage", e)
                synchronized(initializationErrors) {
                    initializationErrors.add(com.pingidentity.authenticatorapp.data.ComponentError("Push", e))
                }
                pushStorageDeferred.completeExceptionally(e)
            }

            // Initialize OATH client with storage (only if storage succeeded)
            val oathError = synchronized(initializationErrors) {
                initializationErrors.find { it.component == "OATH" }
            }
            if (oathError == null) {
                try {
                    oathClient = OathClient {
                        // Use the pre-created storage instance
                        storage = oathStorage
                        // Enable credential caching
                        enableCredentialCache = true
                        // Set diagnostic logger if enabled, otherwise standard logger
                        this.logger = diagnosticLogger
                    }
                    oathClientDeferred.complete(oathClient)
                    diagnosticLogger.i("AuthenticatorApp: OATH client initialized")
                } catch (e: Exception) {
                    diagnosticLogger.e("AuthenticatorApp: Failed to initialize OATH client", e)
                    synchronized(initializationErrors) {
                        initializationErrors.add(com.pingidentity.authenticatorapp.data.ComponentError("OATH", e))
                    }
                    oathClientDeferred.completeExceptionally(e)
                }
            } else {
                oathClientDeferred.completeExceptionally(oathError.exception)
            }

            // Initialize Push client with storage (only if storage succeeded)
            val pushError = synchronized(initializationErrors) {
                initializationErrors.find { it.component == "Push" }
            }
            if (pushError == null) {
                try {
                    pushClient = PushClient {
                        // Use the pre-created storage instance
                        storage = pushStorage
                        // Enable credential caching
                        enableCredentialCache = true
                        // Set diagnostic logger if enabled, otherwise standard logger
                        this.logger = diagnosticLogger
                    }
                    pushClientDeferred.complete(pushClient)
                    diagnosticLogger.i("AuthenticatorApp: Push client initialized")
                } catch (e: Exception) {
                    diagnosticLogger.e("AuthenticatorApp: Failed to initialize Push client", e)
                    synchronized(initializationErrors) {
                        initializationErrors.add(com.pingidentity.authenticatorapp.data.ComponentError("Push", e))
                    }
                    pushClientDeferred.completeExceptionally(e)
                }
            } else {
                pushClientDeferred.completeExceptionally(pushError.exception)
            }

            // Obtain the device token from Firebase and set it in the Push client
            val hasPushError = synchronized(initializationErrors) {
                initializationErrors.any { it.component == "Push" }
            }
            if (!hasPushError) {
                try {
                    FirebaseApp.getInstance()
                    pushClient.setDeviceToken(FirebaseMessaging.getInstance().token.await())
                    diagnosticLogger.i("AuthenticatorApp: Firebase device token set")
                } catch (e: IllegalStateException) {
                    diagnosticLogger.e("Firebase not configured properly", e)
                    synchronized(initializationErrors) {
                        initializationErrors.add(com.pingidentity.authenticatorapp.data.ComponentError("Firebase", e))
                    }
                }
            }
            
            diagnosticLogger.i("AuthenticatorApp: SDK initialization complete")
        }
    }

    companion object {
        /**
         * Creates a configured SQLOathStorage instance with standard settings.
         * This ensures consistency between initialization and backup restoration.
         * 
         * @param context Android application context
         * @param autoRestoreFromBackup Whether to auto-restore from backup on corruption
         * @param allowDestructiveRecovery Whether to allow destructive recovery
         * @param logger Logger instance to use
         */
        fun createOathStorage(
            context: android.content.Context,
            autoRestoreFromBackup: Boolean = true,
            allowDestructiveRecovery: Boolean = false,
            logger: Logger = DiagnosticLogger
        ): SQLOathStorage {
            return SQLOathStorage {
                this.context = context
                this.passphraseProvider = KeyStorePassphraseProvider(
                    context,
                    logger = logger
                )
                this.autoRestoreFromBackup = autoRestoreFromBackup
                this.allowDestructiveRecovery = allowDestructiveRecovery
                this.backupOnError = false
                this.maxBackupCount = 5
                this.logger = logger
            }
        }
        
        /**
         * Creates a configured SQLPushStorage instance with standard settings.
         * This ensures consistency between initialization and backup restoration.
         * 
         * @param context Android application context
         * @param autoRestoreFromBackup Whether to auto-restore from backup on corruption
         * @param allowDestructiveRecovery Whether to allow destructive recovery
         * @param logger Logger instance to use
         */
        fun createPushStorage(
            context: android.content.Context,
            autoRestoreFromBackup: Boolean = true,
            allowDestructiveRecovery: Boolean = false,
            logger: Logger = DiagnosticLogger
        ): SQLPushStorage {
            return SQLPushStorage {
                this.context = context
                this.passphraseProvider = KeyStorePassphraseProvider(
                    context,
                    logger = logger
                )
                this.autoRestoreFromBackup = autoRestoreFromBackup
                this.allowDestructiveRecovery = allowDestructiveRecovery
                this.backupOnError = false
                this.maxBackupCount = 5
                this.logger = logger
            }
        }

        /*
         * Helper method to access the initialized PushClient from application context.
         * This method suspend until the respective component is fully initialized.
         * @param context Application context
         * Throws IllegalStateException if the context is not AuthenticatorApp.
         */
        suspend fun getPushClient(context: Application): PushClient {
            val app = context as? AuthenticatorApp
                ?: throw IllegalStateException("Context must be AuthenticatorApp")

            if (app.pushClientDeferred.isCompleted) {
                return app.pushClientDeferred.getCompleted()
            }
            return app.pushClientDeferred.await()
        }

        /*
         * Helper method to access the initialized OathClient from application context.
         * This method suspend until the respective component is fully initialized.
         * @param context Application context
         * Throws IllegalStateException if the context is not AuthenticatorApp.
         */
        suspend fun getOathClient(context: Application): OathClient {
            val app = context as AuthenticatorApp
            if (app.oathClientDeferred.isCompleted) {
                return app.oathClientDeferred.getCompleted()
            }
            return app.oathClientDeferred.await()
        }

        /*
         * Helper method to access the initialized Journey from application context.
         * This method suspend until the respective component is fully initialized.
         * @param context Application context
         * Throws IllegalStateException if the context is not AuthenticatorApp.
         */
        suspend fun getJourney(context: Application): Journey {
            val app = context as AuthenticatorApp
            if (app.journeyDeferred.isCompleted) {
                return app.journeyDeferred.getCompleted()
            }
            return app.journeyDeferred.await()
        }

        /*
         * Helper method to access the initialized SQLOathStorage from application context.
         * This method suspend until the respective component is fully initialized.
         * @param context Application context
         * Throws IllegalStateException if the context is not AuthenticatorApp.
         */
        suspend fun getOathStorage(context: Application): SQLOathStorage {
            val app = context as? AuthenticatorApp
                ?: throw IllegalStateException("Context must be AuthenticatorApp")
            if (app.oathStorageDeferred.isCompleted) {
                return app.oathStorageDeferred.getCompleted()
            }
            return app.oathStorageDeferred.await()
        }

        /*
         * Helper method to access the initialized SQLPushStorage from application context.
         * This method suspend until the respective component is fully initialized.
         * @param context Application context
         * Throws IllegalStateException if the context is not AuthenticatorApp.
         */
        suspend fun getPushStorage(context: Application): SQLPushStorage {
            val app = context as? AuthenticatorApp
                ?: throw IllegalStateException("Context must be AuthenticatorApp")
            if (app.pushStorageDeferred.isCompleted) {
                return app.pushStorageDeferred.getCompleted()
            }
            return app.pushStorageDeferred.await()
        }
        
        /**
         * Checks if there were any initialization errors.
         * Returns the initialization error if present, null otherwise.
         */
        fun getInitializationError(context: Application): com.pingidentity.authenticatorapp.data.InitializationError? {
            val app = context as? AuthenticatorApp
                ?: throw IllegalStateException("Context must be AuthenticatorApp")
            
            val errors = synchronized(app.initializationErrors) {
                app.initializationErrors.toList()
            }
            
            if (errors.isEmpty()) {
                return null
            }
            
            // Determine error type based on which components failed
            val hasOathError = errors.any { it.component == "OATH" }
            val hasPushError = errors.any { it.component == "Push" }
            val hasJourneyError = errors.any { it.component == "Journey" }
            
            val errorType = when {
                hasOathError && hasPushError -> com.pingidentity.authenticatorapp.data.InitializationErrorType.BOTH_DATABASES_CORRUPTED
                hasOathError -> com.pingidentity.authenticatorapp.data.InitializationErrorType.OATH_DATABASE_CORRUPTED
                hasPushError -> com.pingidentity.authenticatorapp.data.InitializationErrorType.PUSH_DATABASE_CORRUPTED
                hasJourneyError -> com.pingidentity.authenticatorapp.data.InitializationErrorType.JOURNEY_INITIALIZATION_FAILED
                else -> com.pingidentity.authenticatorapp.data.InitializationErrorType.UNKNOWN_ERROR
            }
            
            // Build message from all errors
            val message = errors.joinToString("\n") { error ->
                "${error.component}: ${error.exception.message}"
            }
            
            // Check if destructive recovery is available
            val userPreferences = com.pingidentity.authenticatorapp.data.UserPreferences(context)
            val canUseDestructiveRecovery = !userPreferences.isDestructiveRecoveryEnabled()
            
            return com.pingidentity.authenticatorapp.data.InitializationError(
                type = errorType,
                message = message,
                errors = errors,
                canRestoreFromBackup = true, // We always have backup capability
                canUseDestructiveRecovery = canUseDestructiveRecovery
            )
        }
    }
}
