/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import com.pingidentity.authenticatorapp.R
import com.pingidentity.authenticatorapp.data.AuthenticatorViewModel
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.ui.components.BackNavigationTopAppBar
import com.pingidentity.authenticatorapp.util.QrCodeAnalyzer
import com.pingidentity.mfa.commons.UriScheme
import java.util.concurrent.Executors

/**
 * A screen that uses the device camera to scan QR codes for adding new credentials.
 * It handles camera permissions, displays a camera preview, and processes detected QR codes.
 *
 * @param viewModel The AuthenticatorViewModel instance for managing state and actions.
 * @param onScanComplete Callback invoked when a QR code is successfully scanned and processed.
 * @param onDismiss Callback invoked when the user wants to exit the scanner screen.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QrScannerScreen(
    viewModel: AuthenticatorViewModel,
    onScanComplete: () -> Unit,
    onDismiss: () -> Unit
) {
    val context = LocalContext.current
    val diagnosticLogger = DiagnosticLogger
    val lifecycleOwner = androidx.lifecycle.compose.LocalLifecycleOwner.current
    val snackbarHostState = remember { SnackbarHostState() }

    // Camera permission state
    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.CAMERA
            ) == PackageManager.PERMISSION_GRANTED
        )
    }

    // Request camera permission
    val requestPermissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission(),
        onResult = { isGranted ->
            hasCameraPermission = isGranted
        }
    )

    // Create an executor for background operations
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }

    // Cleanup resources when leaving the screen
    LaunchedEffect(Unit) {
        if (!hasCameraPermission) {
            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
        }
    }

    // Show error message if viewModel has an error
    val uiState by viewModel.uiState.collectAsState()

    // Show success message if a credential was added
    LaunchedEffect(uiState.lastAddedOathCredential) {
        if (uiState.lastAddedOathCredential != null) {
            snackbarHostState.showSnackbar(context.getString(R.string.qr_scanner_account_added_successfully))
            viewModel.clearLastAddedOathCredential()
            onScanComplete()
        }
    }

    // Also check for push credentials
    LaunchedEffect(uiState.lastAddedPushCredential) {
        if (uiState.lastAddedPushCredential != null) {
            snackbarHostState.showSnackbar(context.getString(R.string.qr_scanner_account_added_successfully))
            viewModel.clearLastAddedPushCredential()
            onScanComplete()
        }
    }

    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = stringResource(id = R.string.content_description_scan_qr),
                onBackClick = onDismiss
            )
        },
        snackbarHost = {
            SnackbarHost(hostState = snackbarHostState)
        }
    ) { paddingValues ->
        Box(modifier = Modifier
            .fillMaxSize()
            .padding(paddingValues)) {
            if (hasCameraPermission) {
                // Camera preview
                AndroidView(
                    factory = { context ->
                        val previewView = PreviewView(context).apply {
                            implementationMode = PreviewView.ImplementationMode.PERFORMANCE
                            scaleType = PreviewView.ScaleType.FILL_CENTER
                        }

                        val preview = Preview.Builder()
                            .build()
                            .also {
                                it.surfaceProvider = previewView.surfaceProvider
                            }

                        val selector = CameraSelector.Builder()
                            .requireLensFacing(CameraSelector.LENS_FACING_BACK)
                            .build()

                        // Configure image analysis with higher resolution for large QR codes
                        val imageAnalysis = ImageAnalysis.Builder()
                            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                            .build()

                        imageAnalysis.setAnalyzer(
                            cameraExecutor,
                            QrCodeAnalyzer { qrCodeResult ->
                                // Process the QR code result (otpauth URI, pushauth URI, or mfauth URI)
                                when {
                                    qrCodeResult.startsWith(UriScheme.OTPAUTH.value) -> {
                                        diagnosticLogger.d("QrScannerScreen: Detected OATH QR code")
                                        viewModel.addOathCredentialFromUri(qrCodeResult)
                                        onScanComplete()
                                    }

                                    qrCodeResult.startsWith(UriScheme.PUSHAUTH.value) -> {
                                        diagnosticLogger.d("QrScannerScreen: Detected Push QR code")
                                        viewModel.addPushCredentialFromUri(qrCodeResult)
                                        onScanComplete()
                                    }

                                    qrCodeResult.startsWith(UriScheme.MFAUTH.value) -> {
                                        diagnosticLogger.d("QrScannerScreen: Detected MFA QR code")
                                        viewModel.addMfaCredentialFromUri(qrCodeResult)
                                        onScanComplete()
                                    }

                                    else -> {
                                        // Show error for invalid QR code format
                                        diagnosticLogger.d("QrScannerScreen: Invalid QR code format")
                                        viewModel.setError("Invalid QR code format. Please scan a valid OATH, Push, or MFA authentication QR code.")
                                    }
                                }
                            }
                        )

                        try {
                            // Bind camera use cases
                            val cameraProvider = ProcessCameraProvider.getInstance(context).get()
                            cameraProvider.unbindAll()
                            cameraProvider.bindToLifecycle(
                                lifecycleOwner,
                                selector,
                                preview,
                                imageAnalysis
                            )
                        } catch (e: Exception) {
                            diagnosticLogger.e(
                                "QrScannerScreen: Failed to bind camera use cases",
                                e
                            )
                            viewModel.setError(
                                context.getString(
                                    R.string.qr_scanner_error_camera_init,
                                    e.message
                                )
                            )
                        }

                        previewView
                    },
                    modifier = Modifier.fillMaxSize()
                )

                // Scanning overlay
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(32.dp)
                ) {
                    Text(
                        text = stringResource(id = R.string.qr_scanner_overlay_text),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.8f),
                        textAlign = TextAlign.Center,
                        modifier = Modifier
                            .align(Alignment.BottomCenter)
                            .padding(bottom = 24.dp)
                    )
                }
            } else {
                // Show permission denied message
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Text(
                        text = stringResource(id = R.string.qr_scanner_permission_required),
                        textAlign = TextAlign.Center,
                        style = MaterialTheme.typography.bodyLarge
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(
                        onClick = {
                            requestPermissionLauncher.launch(Manifest.permission.CAMERA)
                        }
                    ) {
                        Text(text = stringResource(id = R.string.qr_scanner_request_permission_button))
                    }
                }
            }

            // Error message
            if (uiState.error != null) {
                AlertDialog(
                    onDismissRequest = { viewModel.clearError() },
                    title = { Text("Error") },
                    text = { Text(uiState.error!!) },
                    confirmButton = {
                        Button(onClick = { viewModel.clearError() }) {
                            Text(stringResource(id = R.string.ok))
                        }
                    }
                )
            }
        }
    }

    // Clean up camera executor when leaving the screen
    DisposableEffect(lifecycleOwner) {
        onDispose {
            cameraExecutor.shutdown()
        }
    }
}
