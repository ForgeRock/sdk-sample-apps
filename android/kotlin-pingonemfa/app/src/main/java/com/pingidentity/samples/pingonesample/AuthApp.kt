/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample

import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.pingidentity.samples.pingonesample.data.PingOneViewModel
import com.pingidentity.samples.pingonesample.theme.AppTheme
import com.pingidentity.samples.pingonesample.ui.AccountsScreen
import com.pingidentity.samples.pingonesample.ui.DiagnosticLogsScreen
import com.pingidentity.samples.pingonesample.ui.QrScannerScreen

/**
 * Root composable for the PingOne MFA sample app.
 *
 * Sets up the Material3 theme and a three-destination navigation graph:
 * - **accounts** — lists registered MFA accounts with live TOTP codes ([AccountsScreen])
 * - **scanner** — camera QR-code scanner and manual-entry panel for pairing new accounts ([QrScannerScreen])
 * - **diagnostics** — in-app log viewer for SDK and app events ([DiagnosticLogsScreen])
 */
@Composable
fun AuthApp(
    pingOneViewModel: PingOneViewModel = viewModel()
) {
    AppTheme {
        Surface(
            modifier = Modifier.fillMaxSize(),
            color = MaterialTheme.colorScheme.background
        ) {
            val navController = rememberNavController()

            NavHost(
                navController = navController,
                startDestination = "accounts"
            ) {
                composable("accounts") {
                    AccountsScreen(
                        viewModel = pingOneViewModel,
                        onScanQrCode = { navController.navigate("scanner") },
                        onDiagnosticLogs = { navController.navigate("diagnostics") },
                    )
                }

                composable("scanner") {
                    QrScannerScreen(
                        viewModel = pingOneViewModel,
                        onScanComplete = { navController.popBackStack() },
                        onDismiss = { navController.popBackStack() },
                    )
                }

                composable("diagnostics") {
                    DiagnosticLogsScreen(
                        onDismiss = { navController.popBackStack() },
                    )
                }
            }
        }
    }
}
