/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.pingonesample.util

import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

/**
 * CameraX [ImageAnalysis.Analyzer] that forwards the raw QR-code string to [onQrCodeScanned]
 * the first time a valid QR code is detected. Uses ML Kit's synchronous barcode scanner.
 *
 * Thread-safety: [close] sets a volatile flag before releasing the ML Kit scanner. [analyze]
 * checks that flag first and closes the [ImageProxy] early — without calling [scanner.process]
 * — so no new task can be submitted after disposal even if the camera executor delivers one
 * more frame during teardown.
 *
 * @param onQrCodeScanned Invoked on the camera executor thread with the raw barcode value.
 */
class QrCodeAnalyzer(
    private val onQrCodeScanned: (String) -> Unit
) : ImageAnalysis.Analyzer {

    private val options = BarcodeScannerOptions.Builder()
        .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
        .build()

    private val scanner = BarcodeScanning.getClient(options)

    @Volatile
    private var closed = false

    /**
     * Processes a single camera frame. Exits early (closing [imageProxy]) if [close] has already
     * been called. Otherwise submits the frame to the ML Kit barcode scanner and invokes
     * [onQrCodeScanned] on the first QR code found.
     *
     * @param imageProxy The camera frame to analyse. Always closed — either immediately on early
     *   exit or via [com.google.android.gms.tasks.Task.addOnCompleteListener].
     */
    @androidx.camera.core.ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        // Guard: if close() has already been called, discard the frame immediately.
        // This prevents scanner.process() from being invoked after scanner.close().
        if (closed) {
            imageProxy.close()
            return
        }

        val mediaImage = imageProxy.image ?: run {
            imageProxy.close()
            return
        }

        val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)

        scanner.process(image)
            .addOnSuccessListener { barcodes ->
                barcodes.firstOrNull()?.rawValue?.let { value ->
                    onQrCodeScanned(value)
                }
            }
            .addOnCompleteListener {
                imageProxy.close()
            }
    }

    /**
     * Releases the ML Kit scanner. After this call [analyze] will close any further
     * [ImageProxy] frames without submitting them to the scanner.
     */
    fun close() {
        closed = true
        scanner.close()
    }
}
