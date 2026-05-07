/*
 * Copyright (c) 2025-2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.ui.components.BackNavigationTopAppBar
import com.pingidentity.authenticatorapp.ui.components.ErrorAlertDialog
import com.pingidentity.mfa.commons.UriScheme
import com.pingidentity.mfa.oath.OathAlgorithm
import com.pingidentity.mfa.oath.OathType

/**
 * A screen that allows users to manually enter details for adding a new OTP credential.
 * The screen includes fields for issuer, account name, secret key, OTP type, algorithm, digits, and period.
 * Upon submission, the entered details are used to create an otpauth URI and add the credential via the ViewModel.
 *
 * @param viewModel The AuthenticatorViewModel instance for managing state and actions.
 * @param onEntryComplete Callback invoked when the entry is successfully completed.
 * @param onDismiss Callback invoked when the user chooses to dismiss the screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManualEntryScreen(
    viewModel: AuthenticatorViewModel,
    onEntryComplete: () -> Unit,
    onDismiss: () -> Unit
) {
    var issuer by remember { mutableStateOf("") }
    var accountName by remember { mutableStateOf("") }
    var secret by remember { mutableStateOf("") }
    var oathType by remember { mutableStateOf(OathType.TOTP) }
    var algorithm by remember { mutableStateOf(OathAlgorithm.SHA1) }
    var digits by remember { mutableStateOf("6") }
    var period by remember { mutableStateOf("30") }

    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val diagnosticLogger = DiagnosticLogger
    val snackbarHostState = remember { SnackbarHostState() }

    // Watch for credential addition success
    LaunchedEffect(uiState.lastAddedOathCredential) {
        if (uiState.lastAddedOathCredential != null) {
            snackbarHostState.showSnackbar(context.getString(R.string.manual_entry_account_added_successfully))
            viewModel.clearLastAddedOathCredential()
            onEntryComplete()
        }
    }

    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = stringResource(id = R.string.manual_entry_screen_title),
                onBackClick = onDismiss
            )
        },
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState)
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(16.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Issuer field
            OutlinedTextField(
                value = issuer,
                onValueChange = { issuer = it },
                label = { Text(stringResource(id = R.string.manual_entry_issuer_label)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Account name field
            OutlinedTextField(
                value = accountName,
                onValueChange = { accountName = it },
                label = { Text(stringResource(id = R.string.manual_entry_account_name_label)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Secret key field
            OutlinedTextField(
                value = secret,
                onValueChange = { secret = it },
                label = { Text(stringResource(id = R.string.manual_entry_secret_key_label)) },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // OTP Type selection
            Text(
                text = stringResource(id = R.string.manual_entry_otp_type_label),
                style = MaterialTheme.typography.bodyLarge
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OathType.entries.forEach { type ->
                    FilterChip(
                        selected = oathType == type,
                        onClick = { oathType = type },
                        label = { Text(type.name) }
                    )
                }
            }

            // Algorithm selection
            Text(
                text = stringResource(id = R.string.manual_entry_algorithm_label),
                style = MaterialTheme.typography.bodyLarge
            )
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                OathAlgorithm.entries.forEach { alg ->
                    FilterChip(
                        selected = algorithm == alg,
                        onClick = { algorithm = alg },
                        label = { Text(alg.name) }
                    )
                }
            }

            // Digits selection
            OutlinedTextField(
                value = digits,
                onValueChange = { if (it.isBlank() || it.toIntOrNull() != null) digits = it },
                label = { Text("Digits") },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true,
                supportingText = {
                    val digitsValue = digits.toIntOrNull()
                    if (digitsValue != null && digitsValue != 6 && digitsValue != 8) {
                        Text(
                            text = "Digits must be 6 or 8 (RFC 4226/6238)",
                            color = MaterialTheme.colorScheme.error
                        )
                    } else {
                        Text("Number of digits in the generated OTP code (6 or 8)")
                    }
                },
                isError = digits.toIntOrNull()?.let { it != 6 && it != 8 } ?: false
            )

            // Period selection (only for TOTP)
            if (oathType == OathType.TOTP) {
                OutlinedTextField(
                    value = period,
                    onValueChange = { if (it.isBlank() || it.toIntOrNull() != null) period = it },
                    label = { Text(stringResource(id = R.string.manual_entry_period_label)) },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.fillMaxWidth(),
                    singleLine = true,
                    supportingText = {
                        val periodValue = period.toIntOrNull()
                        if (periodValue != null && periodValue <= 0) {
                            Text(
                                text = "Period must be greater than 0",
                                color = MaterialTheme.colorScheme.error
                            )
                        } else {
                            Text("Time in seconds for code validity (typically 30)")
                        }
                    },
                    isError = period.toIntOrNull()?.let { it <= 0 } ?: false
                )
            }

            // Submit button
            Button(
                onClick = {
                    // Create otpauth URI and add credential
                    val uri = buildOtpauthUri(
                        issuer = issuer,
                        accountName = accountName,
                        secret = secret,
                        oathType = oathType,
                        algorithm = algorithm,
                        digits = digits.toIntOrNull() ?: 6,
                        period = period.toIntOrNull() ?: 30
                    )
                    diagnosticLogger.d("ManualEntryScreen: Adding credential from URI")
                    viewModel.addOathCredentialFromUri(uri)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 16.dp),
                enabled = issuer.isNotBlank() && 
                         accountName.isNotBlank() && 
                         secret.isNotBlank() &&
                         digits.toIntOrNull()?.let { it == 6 || it == 8 } ?: false &&
                         (oathType == OathType.HOTP || period.toIntOrNull()?.let { it > 0 } ?: false)
            ) {
                Text(stringResource(id = R.string.manual_entry_add_account_button))
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

/**
 * Builds an otpauth URI from the provided parameters.
 * Format: otpauth://totp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30
 */
private fun buildOtpauthUri(
    issuer: String,
    accountName: String,
    secret: String,
    oathType: OathType,
    algorithm: OathAlgorithm,
    digits: Int,
    period: Int
): String {
    return buildString {
        append(UriScheme.OTPAUTH.value)
        append(oathType.name.lowercase())
        append("/")
        append(issuer)
        append(":")
        append(accountName)
        append("?secret=")
        append(secret)
        append("&issuer=")
        append(issuer)
        append("&algorithm=")
        append(algorithm.name)
        append("&digits=")
        append(digits)

        if (oathType == OathType.TOTP) {
            append("&period=")
            append(period)
        }
    }
}
