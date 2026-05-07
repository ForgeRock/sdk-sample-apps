/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.util

import androidx.annotation.OptIn
import android.annotation.SuppressLint
import androidx.camera.core.ExperimentalGetImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import com.pingidentity.mfa.commons.UriScheme
import java.util.concurrent.TimeUnit

/**
 * Analyzes camera images to detect and decode QR codes.
 * 
 * @param onQrCodeDetected Callback that will be invoked when a QR code is successfully scanned
 */
class QrCodeAnalyzer(private val onQrCodeDetected: (String) -> Unit) : ImageAnalysis.Analyzer {
    
    private val scanner = BarcodeScanning.getClient()
    
    // Track when we last detected a QR code to avoid duplicate scans
    private var lastAnalyzedTimestamp = 0L
    
    @SuppressLint("UnsafeOptInUsageError")
    @OptIn(ExperimentalGetImage::class)
    override fun analyze(imageProxy: ImageProxy) {
        val currentTimestamp = System.currentTimeMillis()
        
        // Only analyze if enough time has passed since the last detection
        // to avoid multiple rapid scans of the same code
        if (currentTimestamp - lastAnalyzedTimestamp >= TimeUnit.SECONDS.toMillis(1)) {
            imageProxy.image?.let { image ->
                val inputImage = InputImage.fromMediaImage(image, imageProxy.imageInfo.rotationDegrees)
                
                scanner.process(inputImage)
                    .addOnSuccessListener { barcodes ->
                        // Process QR codes and find the first valid barcode
                        val foundQrCode = barcodes.find { barcode ->
                            barcode.format == Barcode.FORMAT_QR_CODE && 
                            barcode.rawValue != null && (
                                barcode.rawValue?.startsWith(UriScheme.OTPAUTH.value) == true ||
                                barcode.rawValue?.startsWith(UriScheme.PUSHAUTH.value) == true ||
                                barcode.rawValue?.startsWith(UriScheme.MFAUTH.value) == true
                            )
                        }
                        
                        // If we found a matching QR code, process it
                        foundQrCode?.rawValue?.let { qrContent ->
                            lastAnalyzedTimestamp = currentTimestamp
                            onQrCodeDetected(qrContent)
                        }
                    }
                    .addOnFailureListener { exception ->
                        // Handle any errors during scanning
                        exception.printStackTrace()
                    }
                    .addOnCompleteListener {
                        // Close the image when done with analysis regardless of success or failure
                        imageProxy.close()
                    }
            } ?: imageProxy.close()
        } else {
            imageProxy.close()
        }
    }
}
