/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Image
import androidx.compose.ui.res.painterResource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.ui.components.BackNavigationTopAppBar
import com.pingidentity.authenticatorapp.ui.components.ContinueNodeRenderer
import com.pingidentity.authenticatorapp.data.LoginViewModel
import com.pingidentity.orchestrate.ContinueNode

/**
 * Screen for Journey-based authentication and credential enrollment
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    viewModel: LoginViewModel,
    onNavigateBack: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    
    // Start the journey when screen is first displayed
    LaunchedEffect(Unit) {
        viewModel.startJourney()
    }
    
    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = stringResource(id = R.string.login_title),
                onBackClick = onNavigateBack
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp),
            contentAlignment = Alignment.Center
        ) {
            // Add Ping logo at the top center
            Image(
                painter = painterResource(id = R.drawable.ping_logo),
                contentDescription = "Ping Identity Logo",
                modifier = Modifier
                    .align(Alignment.TopCenter)
                    .size(80.dp)
                    .padding(top = 16.dp)
            )
            when {
                uiState.isSuccess -> {
                    SuccessContent(
                        message = uiState.message ?: stringResource(id = R.string.login_success_message),
                        onDone = {
                            // Logout the user to clear session after successful MFA registration
                            viewModel.logout()
                            onNavigateBack()
                        }
                    )
                }
                
                uiState.error != null -> {
                    val currentError = uiState.error ?: stringResource(id = R.string.login_unknown_error)
                    ErrorContent(
                        error = currentError,
                        onRetry = { 
                            viewModel.reset()
                            viewModel.startJourney() 
                        },
                        onDone = onNavigateBack
                    )
                }
                
                uiState.isLoading -> {
                    LoadingContent(
                        message = uiState.message ?: stringResource(id = R.string.login_loading_message),
                        isPolling = uiState.isPolling
                    )
                }
                
                uiState.isMfaRegistering -> {
                    LoadingContent(
                        message = uiState.message ?: stringResource(id = R.string.login_registering_message),
                        isPolling = false
                    )
                }
                
                uiState.currentNode is ContinueNode -> {
                    // Show journey callbacks for user interaction
                    val continueNode = uiState.currentNode as ContinueNode
                    ContinueNodeRenderer(
                        node = continueNode,
                        onNodeUpdated = { viewModel.refreshNode() },
                        onNext = { viewModel.nextStep() }
                    )
                }
                
                else -> {
                    // Initial state
                    LoadingContent(
                        message = stringResource(id = R.string.login_initial_message),
                        isPolling = false
                    )
                }
            }
        }
    }
}

/**
 * Success state content
 */
@Composable
private fun SuccessContent(
    message: String,
    onDone: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.CheckCircle,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
                modifier = Modifier.size(64.dp)
            )
            
            Text(
                text = "Success!",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.primary
            )
            
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Button(
                onClick = onDone,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Done")
            }
        }
    }
}

/**
 * Error state content
 */
@Composable
private fun ErrorContent(
    error: String,
    onRetry: () -> Unit,
    onDone: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Icon(
                imageVector = Icons.Default.Error,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.error,
                modifier = Modifier.size(64.dp)
            )
            
            Text(
                text = "Authentication Failed",
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.error
            )
            
            Text(
                text = error,
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Button(
                    onClick = onRetry,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text( stringResource(R.string.login_retry))
                }
                
                Button(
                    onClick = onDone,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(stringResource(id = R.string.login_cancel))
                }
            }
        }
    }
}

/**
 * Loading state content
 */
@Composable
private fun LoadingContent(
    message: String,
    isPolling: Boolean
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainer
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (isPolling) {
                // Animated progress indicator for polling
                val infiniteTransition = rememberInfiniteTransition(label = "polling")
                val progressAnimationValue by infiniteTransition.animateFloat(
                    initialValue = 0.0f,
                    targetValue = 1.0f,
                    animationSpec = infiniteRepeatable(animation = tween(2000)),
                    label = "polling_progress"
                )
                
                CircularProgressIndicator(
                    progress = { progressAnimationValue },
                    modifier = Modifier.size(64.dp),
                    strokeWidth = 6.dp
                )
            } else {
                // Indeterminate progress indicator
                CircularProgressIndicator(
                    modifier = Modifier.size(64.dp),
                    strokeWidth = 6.dp
                )
            }
            
            Text(
                text = if (isPolling) stringResource(R.string.login_wait_message) else stringResource(R.string.login_loading_message),
                style = MaterialTheme.typography.headlineSmall,
                color = MaterialTheme.colorScheme.primary
            )
            
            Text(
                text = message,
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}
