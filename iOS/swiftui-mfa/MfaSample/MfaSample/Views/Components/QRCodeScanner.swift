//
//  QRCodeScanner.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import AVFoundation

/// SwiftUI wrapper for AVFoundation QR code scanner.
struct QRCodeScanner: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned, onError: onError)
    }

    class Coordinator: NSObject, QRCodeScannerDelegate {
        let onCodeScanned: (String) -> Void
        let onError: (Error) -> Void

        init(onCodeScanned: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
            self.onCodeScanned = onCodeScanned
            self.onError = onError
        }

        func qrCodeScanner(_ scanner: QRCodeScannerViewController, didScanCode code: String) {
            onCodeScanned(code)
        }

        func qrCodeScanner(_ scanner: QRCodeScannerViewController, didFailWithError error: Error) {
            onError(error)
        }
    }
}

// MARK: - Scanner Delegate Protocol

protocol QRCodeScannerDelegate: AnyObject {
    func qrCodeScanner(_ scanner: QRCodeScannerViewController, didScanCode code: String)
    func qrCodeScanner(_ scanner: QRCodeScannerViewController, didFailWithError error: Error)
}

// MARK: - Scanner View Controller

class QRCodeScannerViewController: UIViewController {
    weak var delegate: QRCodeScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    private func setupCaptureSession() {
        let session = AVCaptureSession()

        // Get camera device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.qrCodeScanner(self, didFailWithError: ScannerError.noCameraAvailable)
            return
        }

        // Create input
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.qrCodeScanner(self, didFailWithError: error)
            return
        }

        // Add input to session
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            delegate?.qrCodeScanner(self, didFailWithError: ScannerError.cannotAddInput)
            return
        }

        // Create output
        let metadataOutput = AVCaptureMetadataOutput()

        // Add output to session
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.qrCodeScanner(self, didFailWithError: ScannerError.cannotAddOutput)
            return
        }

        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        self.captureSession = session
        self.previewLayer = previewLayer
    }

    private func startScanning() {
        hasScanned = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    private func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    func resetScanning() {
        hasScanned = false
        startScanning()
    }
}

// MARK: - Metadata Output Delegate

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        guard !hasScanned,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }

        // Prevent multiple scans
        hasScanned = true
        stopScanning()

        // Haptic feedback
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

        // Notify delegate
        delegate?.qrCodeScanner(self, didScanCode: stringValue)
    }
}

// MARK: - Scanner Errors

enum ScannerError: LocalizedError {
    case noCameraAvailable
    case cannotAddInput
    case cannotAddOutput
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noCameraAvailable:
            return "No camera available on this device"
        case .cannotAddInput:
            return "Cannot add camera input to capture session"
        case .cannotAddOutput:
            return "Cannot add metadata output to capture session"
        case .permissionDenied:
            return "Camera permission denied. Please enable camera access in Settings."
        }
    }
}
