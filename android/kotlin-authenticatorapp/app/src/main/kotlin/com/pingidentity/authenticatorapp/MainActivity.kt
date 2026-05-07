/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp

import android.Manifest
import android.app.Application
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.data.LoginViewModel
import com.pingidentity.authenticatorapp.data.ThemeMode
import com.pingidentity.authenticatorapp.data.UserPreferences
import com.pingidentity.authenticatorapp.managers.AccountGroupingManager
import com.pingidentity.authenticatorapp.managers.JourneyManager
import com.pingidentity.authenticatorapp.managers.OathManager
import com.pingidentity.authenticatorapp.managers.PushManager
import com.pingidentity.authenticatorapp.managers.TestAccountFactory
import com.pingidentity.authenticatorapp.notification.NotificationHelper
import com.pingidentity.authenticatorapp.ui.AuthenticatorNavHost
import com.pingidentity.authenticatorapp.ui.theme.PingIdentityAuthenticatorTheme
import kotlinx.coroutines.launch

/**
 * Main activity for the Authenticator app.
 * Sets up the content view with Jetpack Compose and handles notification permissions.
 */
class MainActivity : ComponentActivity() {

    private lateinit var authenticatorViewModel: AuthenticatorViewModel
    private lateinit var loginViewModel: LoginViewModel
    private var areViewModelsInitialized by mutableStateOf(false)

    // Register for notification permission result
    private val requestPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted: Boolean ->
        // Check if ViewModel is initialized before using it
        if (::authenticatorViewModel.isInitialized) {
            if (isGranted) {
                // Permission granted, notifications can be shown
                authenticatorViewModel.setMessage(getString(R.string.notification_permission_granted))
            } else {
                // Permission denied
                authenticatorViewModel.setMessage(getString(R.string.notification_permission_denied))
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Setup ViewModels with dependencies
        setupViewModels(application)

        // Initialize notification channels
        NotificationHelper(this).createNotificationChannels()
        
        // Check notification permission for Android 13+
        checkNotificationPermission()

        setContent {
            if (areViewModelsInitialized) {
                val themeMode by authenticatorViewModel.themeMode.collectAsState()
                PingIdentityAuthenticatorTheme(themeMode = themeMode) {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        AuthenticatorNavHost(
                            authenticatorViewModel = authenticatorViewModel,
                            loginViewModel = loginViewModel,
                            initialDestination = getInitialDestination()
                        )
                    }
                }
            } else {
                // Show a basic loading screen with system theme while ViewModels initialize
                PingIdentityAuthenticatorTheme(themeMode = ThemeMode.SYSTEM) {
                    Surface(
                        modifier = Modifier.fillMaxSize(),
                        color = MaterialTheme.colorScheme.background
                    ) {
                        // You could add a proper loading screen here if needed
                    }
                }
            }
        }
    }

    /**
     * Sets up the ViewModels with their dependencies.
     */
    private fun setupViewModels(application: Application) {
        // Initialize clients and ViewModels asynchronously
        lifecycleScope.launch {
            val diagnosticLogger = DiagnosticLogger
            val userPreferences = UserPreferences(application)
            val oathManager = OathManager(diagnosticLogger = diagnosticLogger)
            val pushManager = PushManager(diagnosticLogger = diagnosticLogger)
            val journeyManager = JourneyManager(diagnosticLogger = diagnosticLogger)

            // Check for initialization errors first
            val initError = AuthenticatorApp.getInitializationError(application)
            
            if (initError != null) {
                // Create ViewModels even with errors so we can show the error screen
                authenticatorViewModel = AuthenticatorViewModel(
                    application = application,
                    userPreferences = userPreferences,
                    oathManager = oathManager,
                    pushManager = pushManager,
                    accountGroupingManager = AccountGroupingManager(userPreferences, diagnosticLogger),
                    testAccountFactory = TestAccountFactory()
                )
                
                loginViewModel = LoginViewModel(
                    application = application,
                    journeyManager = journeyManager,
                    oathManager = oathManager,
                    pushManager = pushManager
                )
                
                // Set the initialization error in the ViewModel
                authenticatorViewModel.setInitializationError(initError)
                
                // Mark ViewModels as initialized
                areViewModelsInitialized = true
                return@launch
            }

            // Get storage instances (will throw if initialization failed)
            try {
                val oathStorage = AuthenticatorApp.getOathStorage(application)
                val pushStorage = AuthenticatorApp.getPushStorage(application)

                // Initialize the clients in the managers
                val journeyClient = AuthenticatorApp.getJourney(application)
                journeyManager.setClient(journeyClient)
                val oauthClient = AuthenticatorApp.getOathClient(application)
                oathManager.setClient(oauthClient, oathStorage)
                val pushClient = AuthenticatorApp.getPushClient(application)
                pushManager.setClient(pushClient, pushStorage)

                // Create ViewModels with clients already set
                authenticatorViewModel = AuthenticatorViewModel(
                    application = application,
                    userPreferences = userPreferences,
                    oathManager = oathManager,
                    pushManager = pushManager,
                    accountGroupingManager = AccountGroupingManager(userPreferences, diagnosticLogger),
                    testAccountFactory = TestAccountFactory()
                )

                // Create LoginViewModel
                loginViewModel = LoginViewModel(
                    application = application,
                    journeyManager = journeyManager,
                    oathManager = oathManager,
                    pushManager = pushManager
                )

                // Mark ViewModels as initialized and trigger UI update
                areViewModelsInitialized = true
            } catch (e: Exception) {
                diagnosticLogger.e("Failed to initialize ViewModels", e)
                
                // Check if there are initialization errors to display
                val errorAfterException = AuthenticatorApp.getInitializationError(application)
                
                // Create basic ViewModels to show error
                authenticatorViewModel = AuthenticatorViewModel(
                    application = application,
                    userPreferences = userPreferences,
                    oathManager = oathManager,
                    pushManager = pushManager,
                    accountGroupingManager = AccountGroupingManager(userPreferences, diagnosticLogger),
                    testAccountFactory = TestAccountFactory()
                )
                
                loginViewModel = LoginViewModel(
                    application = application,
                    journeyManager = journeyManager,
                    oathManager = oathManager,
                    pushManager = pushManager
                )
                
                // Set the error if we found one
                if (errorAfterException != null) {
                    authenticatorViewModel.setInitializationError(errorAfterException)
                }
                
                areViewModelsInitialized = true
            }
        }
    }
    
    /**
     * Checks if notification permission is granted and requests if not
     * (required for Android 13+/API 33+)
     */
    private fun checkNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            val permissionState = ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
            
            if (permissionState != PackageManager.PERMISSION_GRANTED) {
                requestPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
    }
    
    /**
     * Determines the initial destination based on intent extras
     * (e.g., when opened from a notification)
     */
    private fun getInitialDestination(): String {
        // Check if opened from a notification
        intent?.extras?.let { extras ->
            if (extras.containsKey("NAVIGATE_TO")) {
                val destination = extras.getString("NAVIGATE_TO") ?: return "accounts"
                
                // If we have a notification ID, navigate to that notification
                if (destination == "notifications" && extras.containsKey("NOTIFICATION_ID")) {
                    val notificationId = extras.getString("NOTIFICATION_ID") ?: return "notifications"
                    return "notification/$notificationId"
                }
                
                return destination
            }
        }
        
        return "accounts"
    }
}
