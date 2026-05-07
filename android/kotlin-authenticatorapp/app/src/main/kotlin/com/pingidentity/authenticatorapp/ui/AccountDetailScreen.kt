/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import android.content.Context
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Snackbar
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.ui.components.AccountAvatar
import com.pingidentity.authenticatorapp.ui.components.BackNavigationTopAppBar
import com.pingidentity.authenticatorapp.ui.components.CircularProgressTimer
import com.pingidentity.authenticatorapp.ui.components.DetailRow
import com.pingidentity.authenticatorapp.ui.components.ErrorAlertDialog
import com.pingidentity.authenticatorapp.ui.components.InfoCard
import com.pingidentity.mfa.oath.OathCodeInfo
import com.pingidentity.mfa.oath.OathCredential
import com.pingidentity.mfa.oath.OathType
import com.pingidentity.mfa.push.PushCredential
import kotlinx.coroutines.delay

/**
 * Screen for displaying account details with both OATH and PUSH credentials.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountDetailScreen(
    issuer: String,
    accountName: String,
    viewModel: AuthenticatorViewModel,
    onDismiss: () -> Unit
) {
    val uiState by viewModel.uiState.collectAsState()
    rememberCoroutineScope()
    
    // Find all credentials matching the issuer and account name
    val oathCredentials = uiState.oathCredentials.filter { 
        it.issuer == issuer && it.accountName == accountName 
    }
    val pushCredentials = uiState.pushCredentials.filter { 
        it.issuer == issuer && it.accountName == accountName 
    }
    
    // Get codes for all OATH credentials
    val oathCodesMap = oathCredentials.associateWith { credential ->
        uiState.generatedCodes[credential.id]
    }
    
    // Clipboard manager to copy codes
    val clipboardManager = LocalClipboardManager.current
    var showCopyConfirmation by remember { mutableStateOf(false) }
    
    // Auto-refresh for TOTP codes for all OATH credentials
    LaunchedEffect(oathCredentials) {
        if (oathCredentials.isNotEmpty()) {
            while (true) {
                oathCredentials.forEach { credential ->
                    if (credential.oathType == OathType.TOTP) {
                        viewModel.generateCode(credential.id)
                    }
                }
                delay(1000)
            }
        }
    }
    
    // Generate initial codes for HOTP credentials
    LaunchedEffect(oathCredentials) {
        oathCredentials.forEach { credential ->
            if (credential.oathType == OathType.HOTP && oathCodesMap[credential] == null) {
                viewModel.generateCode(credential.id)
            }
        }
    }
    
    
    // Copy toast timeout
    LaunchedEffect(showCopyConfirmation) {
        if (showCopyConfirmation) {
            delay(2000)
            showCopyConfirmation = false
        }
    }
    
    // Get display names from the first available credential
    val displayIssuer = oathCredentials.firstOrNull()?.displayIssuer 
        ?: pushCredentials.firstOrNull()?.displayIssuer 
        ?: issuer
    val displayAccountName = oathCredentials.firstOrNull()?.displayAccountName 
        ?: pushCredentials.firstOrNull()?.displayAccountName 
        ?: accountName
    
    // Use the display issuer for the title
    val accountIssuer = displayIssuer.ifEmpty { stringResource(id = R.string.account_detail_empty_issuer) }
    
    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = accountIssuer,
                onBackClick = onDismiss
            )
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            if (oathCredentials.isEmpty() && pushCredentials.isEmpty()) {
                // Account not found
                Text(
                    text = stringResource(id = R.string.account_detail_no_credentials),
                    modifier = Modifier
                        .align(Alignment.Center)
                        .padding(16.dp)
                )
            } else {
                // Account details
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(8.dp)
                        .verticalScroll(rememberScrollState()),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // Account Image/Avatar
                    val imageUrl = oathCredentials.firstOrNull()?.imageURL 
                        ?: pushCredentials.firstOrNull()?.imageURL
                    
                    AccountAvatar(
                        issuer = displayIssuer,
                        accountName = displayAccountName,
                        imageUrl = imageUrl,
                        size = 60.dp
                    )
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    // Issuer and Account Name below the logo
                    Text(
                        text = displayIssuer,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Text(
                        text = displayAccountName,
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))

                    // OATH Section
                    if (oathCredentials.isNotEmpty()) {
                        OathCredentialsSection(
                            oathCredentials = oathCredentials,
                            oathCodesMap = oathCodesMap,
                            onGenerateCode = { credentialId -> viewModel.generateCode(credentialId) },
                            onCopyCode = { code ->
                                clipboardManager.setText(AnnotatedString(code))
                                showCopyConfirmation = true
                            }
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                    
                    // PUSH Section
                    if (pushCredentials.isNotEmpty()) {
                        PushCredentialsSection(
                            pushCredentials = pushCredentials
                        )
                    }
                }
            }
            
            // Show copy confirmation
            if (showCopyConfirmation) {
                Snackbar(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(16.dp)
                ) {
                    Text(stringResource(id = R.string.account_detail_code_copied))
                }
            }
            
            
            // Error handling
            if (uiState.error != null) {
                ErrorAlertDialog(
                    errorMessage = uiState.error!!,
                    onDismiss = { viewModel.clearError() }
                )
            }
        }
    }
}

@Composable
fun OathCredentialsSection(
    oathCredentials: List<OathCredential>,
    oathCodesMap: Map<OathCredential, OathCodeInfo?>,
    onGenerateCode: (String) -> Unit,
    onCopyCode: (String) -> Unit
) {
    val context = LocalContext.current
    InfoCard(
        title = stringResource(id = R.string.account_detail_oath)
    ) {
        Column {
            
            oathCredentials.forEachIndexed { index, credential ->
                if (index > 0) {
                    Spacer(modifier = Modifier.height(16.dp))
                }
                
                // Display code if available
                val codeInfo = oathCodesMap[credential]
                codeInfo?.let { info ->
                    // Calculate progress for TOTP
                    val progress = if (credential.oathType == OathType.TOTP) {
                        info.progress.toFloat()
                    } else {
                        0f
                    }
                    
                    // Code with countdown timer
                    Box(
                        modifier = Modifier
                            .padding(vertical = 16.dp)
                            .size(150.dp)
                            .align(Alignment.CenterHorizontally),
                        contentAlignment = Alignment.Center
                    ) {
                        // Circular progress indicator for TOTP
                        if (credential.oathType == OathType.TOTP) {
                            CircularProgressTimer(
                                progress = progress,
                                modifier = Modifier.matchParentSize()
                            )
                        }
                        
                        // Show the actual code
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = info.code,
                                style = MaterialTheme.typography.headlineMedium
                            )
                        }
                    }
                    
                    // Action buttons
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally)
                    ) {
                        Button(
                            onClick = { onCopyCode(info.code) }
                        ) {
                            Icon(Icons.Default.ContentCopy, contentDescription = null)
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(stringResource(id = R.string.copy))
                        }
                        
                        // Refresh button for HOTP
                        if (credential.oathType == OathType.HOTP) {
                            Button(
                                onClick = { onGenerateCode(credential.id) }
                            ) {
                                Icon(Icons.Default.Refresh, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(stringResource(id = R.string.new_code))
                            }
                        }
                    }
                } ?: run {
                    // No code available, show generate button
                    Button(
                        onClick = { onGenerateCode(credential.id) },
                        modifier = Modifier
                            .align(Alignment.CenterHorizontally)
                            .padding(16.dp)
                    ) {
                        Text(stringResource(id = R.string.generate_code))
                    }
                }
                
                // Credential details
                Spacer(modifier = Modifier.height(16.dp))
                DetailRow(label = stringResource(id = R.string.detail_row_type), value = credential.oathType.name)
                DetailRow(label = stringResource(id = R.string.detail_row_algorithm), value = credential.oathAlgorithm.name)
                DetailRow(label = stringResource(id = R.string.detail_row_digits), value = credential.digits.toString())
                if (credential.oathType == OathType.TOTP) {
                    DetailRow(label = stringResource(id = R.string.detail_row_period), value = stringResource(id = R.string.period_seconds, credential.period))
                }
                DetailRow(label = stringResource(id = R.string.detail_row_created), value = formatDate(context, credential.createdAt))
                credential.userId?.let { userId ->
                    DetailRow(label = stringResource(id = R.string.detail_row_user_id), value = userId)
                }
            }
        }
    }
}

@Composable
fun PushCredentialsSection(
    pushCredentials: List<PushCredential>
) {
    val context = LocalContext.current
    InfoCard(
        title = stringResource(id = R.string.account_detail_push)
    ) {
        Column {
            pushCredentials.forEachIndexed { index, credential ->
                if (index > 0) {
                    Spacer(modifier = Modifier.height(16.dp))
                }

                DetailRow(label = stringResource(id = R.string.detail_row_platform), value = formatPlatform(context, credential.platform))
                DetailRow(label = stringResource(id = R.string.detail_row_created), value = formatDate(context, credential.createdAt))
                credential.userId?.let { userId ->
                    DetailRow(label = stringResource(id = R.string.detail_row_user_id), value = userId)
                }
            }
        }
    }
}

// Helper function to format platform name
private fun formatPlatform(context: Context, platform: String): String {
    return when (platform) {
        "PING_AM" -> context.getString(R.string.platform_ping_am)
        "PING_ONE" -> context.getString(R.string.platform_ping_one)
        else -> platform
    }
}

// Helper function to format date
private fun formatDate(context: Context, date: java.util.Date): String {
    val now = java.util.Date()
    val diffInMillis = now.time - date.time
    val diffInDays = diffInMillis / (1000 * 60 * 60 * 24)
    
    return when {
        diffInDays == 0L -> context.getString(R.string.date_today)
        diffInDays == 1L -> context.getString(R.string.date_yesterday)
        diffInDays < 7 -> context.getString(R.string.date_days_ago, diffInDays)
        diffInDays < 30 -> context.getString(R.string.date_weeks_ago, diffInDays / 7)
        diffInDays < 365 -> context.getString(R.string.date_months_ago, diffInDays / 30)
        else -> context.getString(R.string.date_years_ago, diffInDays / 365)
    }
}

