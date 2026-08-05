/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.ui

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.activity.compose.LocalActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
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
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.LocalLifecycleOwner
import com.pingidentity.samples.pingonesample.R
import com.pingidentity.samples.pingonesample.data.PingOneViewModel
import com.pingidentity.samples.pingonesample.ui.components.BackNavigationTopAppBar
import com.pingidentity.samples.pingonesample.ui.components.LoadingIndicator
import com.pingidentity.samples.pingonesample.ui.components.ManualPairingPanel
import com.pingidentity.samples.pingonesample.ui.components.QrGrid
import com.pingidentity.samples.pingonesample.util.QrCodeAnalyzer
import java.util.concurrent.Executors

/**
 * Camera-based QR code scanner that pairs a new account via the PingOne MFA SDK.
 *
 * Handles camera permission requests, displays a live preview with a framing overlay,
 * and delegates QR code processing to [PingOneViewModel.pairAccount].
 *
 * @param viewModel Shared [PingOneViewModel].
 * @param onScanComplete Called after a QR code is successfully processed.
 * @param onDismiss Called when the user presses the back button.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun QrScannerScreen(
    viewModel: PingOneViewModel,
    onScanComplete: () -> Unit,
    onDismiss: () -> Unit,
) {
    val context = LocalContext.current
    val activity = LocalActivity.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }
    var manualKey by remember { mutableStateOf("") }

    // ---- permission ----
    var hasCameraPermission by remember {
        mutableStateOf(
            ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
                    == PackageManager.PERMISSION_GRANTED
        )
    }
    // True when the user has permanently denied (checked before the launcher fires the dialog)
    var isPermanentlyDenied by remember { mutableStateOf(false) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestPermission()
    ) { granted ->
        hasCameraPermission = granted
        if (!granted) {
            // If the system didn't show a rationale after denial, it's permanently denied
            isPermanentlyDenied = activity?.let {
                !it.shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)
            } ?: false
        }
    }

    LaunchedEffect(Unit) {
        if (!hasCameraPermission) permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    // ---- camera executor ----
    val cameraExecutor = remember { Executors.newSingleThreadExecutor() }

    // ---- success / error snackbars ----
    LaunchedEffect(uiState.successMessage) {
        uiState.successMessage?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearMessage()
            onScanComplete()
        }
    }
    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    // ---- prevent re-scanning while pairing ----
    // AtomicBoolean provides the required visibility and compare-and-set atomicity.
    val scanned = remember { java.util.concurrent.atomic.AtomicBoolean(false) }
    LaunchedEffect(uiState.isPairing) {
        if (!uiState.isPairing) scanned.set(false)
    }

    // ---- single QR analyzer, closed in the DisposableEffect below ----
    // Wrap viewModel in rememberUpdatedState so the analyzer's lambda always sees
    // the latest instance without being reallocated (and thus keeps a stable ML Kit client).
    val currentViewModel by rememberUpdatedState(viewModel)
    val qrAnalyzer = remember {
        QrCodeAnalyzer { qrValue ->
            if (scanned.compareAndSet(false, true)) {
                currentViewModel.pairAccount(qrValue)
            }
        }
    }

    val cameraErrorTemplate = stringResource(R.string.qr_scanner_camera_error)

    Scaffold(
        topBar = {
            BackNavigationTopAppBar(
                title = stringResource(R.string.qr_scanner_title),
                onBackClick = onDismiss,
            )
        },
        snackbarHost = { SnackbarHost(hostState = snackbarHostState) }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .navigationBarsPadding(),
        ) {
            // Camera area — fills all space above the manual-entry panel
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .background(Color(0xFF616161)),
                contentAlignment = Alignment.Center,
            ) {
                if (hasCameraPermission && !uiState.isPairing) {
                    // Full-size camera preview behind the overlay
                    AndroidView(
                        modifier = Modifier.fillMaxSize(),
                        factory = { ctx ->
                            val previewView = PreviewView(ctx).apply {
                                implementationMode = PreviewView.ImplementationMode.PERFORMANCE
                                scaleType = PreviewView.ScaleType.FILL_CENTER
                            }

                            val preview = Preview.Builder().build().also {
                                it.surfaceProvider = previewView.surfaceProvider
                            }

                            val imageAnalysis = ImageAnalysis.Builder()
                                .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                                .build()
                                .also { analysis ->
                                    analysis.setAnalyzer(cameraExecutor, qrAnalyzer)
                                }

                            // Bind asynchronously via addListener so the factory lambda (which
                            // runs on the main thread) never blocks waiting for the CameraProvider
                            // future to resolve on a cold start.
                            //
                            // Two constraints drive the executor and future-capture choices:
                            //  1. The listener executor must be the main executor because
                            //     CameraX enforces @MainThread on unbindAll() and bindToLifecycle().
                            //     Using cameraExecutor here throws IllegalStateException at runtime.
                            //  2. The future reference must be captured before addListener (into
                            //     cameraProviderFuture) so that inside the callback we call .get()
                            //     on the same already-resolved future — not a second getInstance()
                            //     call whose future may not yet be complete and would block.
                            val cameraProviderFuture = ProcessCameraProvider.getInstance(ctx)
                            cameraProviderFuture.addListener(
                                {
                                    try {
                                        val cameraProvider = cameraProviderFuture.get()
                                        cameraProvider.unbindAll()
                                        cameraProvider.bindToLifecycle(
                                            lifecycleOwner,
                                            CameraSelector.DEFAULT_BACK_CAMERA,
                                            preview,
                                            imageAnalysis
                                        )
                                    } catch (e: Exception) {
                                        viewModel.setError(cameraErrorTemplate.format(e.message))
                                    }
                                },
                                ContextCompat.getMainExecutor(ctx)
                            )

                            previewView
                        },
                    )
                }
                if (uiState.isPairing) {
                    // Pairing in flight — show spinner over the solid gray background
                    LoadingIndicator(
                        message = stringResource(R.string.qr_scanner_pairing_in_progress),
                        modifier = Modifier.fillMaxSize(),
                    )
                } else if (hasCameraPermission) {
                    // Overlay: label + corner-bracket scanning window
                    QrGrid()
                }

                // Permission-denied fallback shown on top of the gray background
                if (!hasCameraPermission && !uiState.isPairing) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center,
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(24.dp),
                    ) {
                        Text(
                            text = if (isPermanentlyDenied)
                                stringResource(R.string.qr_scanner_permission_permanently_denied)
                            else
                                stringResource(R.string.qr_scanner_permission_required),
                            color = Color.White,
                            textAlign = TextAlign.Center,
                            style = MaterialTheme.typography.bodyLarge,
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(
                            onClick = {
                                if (isPermanentlyDenied) {
                                    // Open app settings so the user can grant manually
                                    context.startActivity(
                                        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                            data = Uri.fromParts("package", context.packageName, null)
                                        }
                                    )
                                } else {
                                    permissionLauncher.launch(Manifest.permission.CAMERA)
                                }
                            }
                        ) {
                            Text(
                                if (isPermanentlyDenied) stringResource(R.string.qr_scanner_open_settings_button)
                                else stringResource(R.string.qr_scanner_grant_permission_button)
                            )
                        }
                    }
                }
                // Manual entry panel pinned at the bottom
                ManualPairingPanel(
                    modifier = Modifier.align(Alignment.BottomCenter),
                    value = manualKey,
                    onValueChange = { manualKey = it },
                    onPair = { key ->
                        viewModel.pairAccount(key)
                        manualKey = ""
                    },
                    isPairing = uiState.isPairing
                )
            }
        }
    }

    DisposableEffect(lifecycleOwner) {
        onDispose {
            // Shut down the camera thread executor and release the ML Kit barcode client
            // together, so neither outlives the other once the screen leaves composition.
            qrAnalyzer.close()
            cameraExecutor.shutdown()
        }
    }
}

