//
//  QRScannerViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import AVFoundation
import PingOath

/// ViewModel for QR code scanning and credential registration.
@MainActor
class QRScannerViewModel: ObservableObject {
    // MARK: - Dependencies
    private let oathManager = OathManager.shared
    private let pushManager = PushManager.shared

    // MARK: - Published State
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var shouldDismiss = false

    // MARK: - Initialization
    init() {
        checkCameraPermission()
    }

    // MARK: - Camera Permission
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestCameraPermission() async {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        cameraPermissionStatus = granted ? .authorized : .denied
    }

    // MARK: - QR Code Processing
    func handleScannedCode(_ code: String) async {
        guard !isProcessing else { return }

        isProcessing = true
        errorMessage = nil
        successMessage = nil

        // Parse QR code to detect type
        let parseResult = QRCodeParser.parse(code)

        switch parseResult {
        case .oath(let uri):
            await registerOathCredential(uri)

        case .push(let uri):
            await registerPushCredential(uri)

        case .mfa(let uri):
            // SDK should handle combined MFA URIs directly
            await registerMfaCredential(uri)

        case .invalid(let message):
            errorMessage = message
            isProcessing = false
        }
    }

    // MARK: - Credential Registration
    private func registerOathCredential(_ uri: String) async {
        do {
            _ = try await oathManager.addCredentialFromUri(uri)
            successMessage = "OATH credential registered successfully"
            isProcessing = false

            // Dismiss after short delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
            shouldDismiss = true

        } catch {
            errorMessage = "Failed to register OATH credential: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func registerPushCredential(_ uri: String) async {
        do {
            _ = try await pushManager.addCredentialFromUri(uri)
            successMessage = "Push credential registered successfully"
            isProcessing = false

            // Dismiss after short delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
            shouldDismiss = true

        } catch {
            errorMessage = "Failed to register Push credential: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func registerMfaCredential(_ uri: String) async {
        // Try to register as both OATH and Push.
        // The SDK will handle the mfauth:// format and extract both components.
        var registeredAnyCredential = false
        var failures: [String] = []

        do {
            _ = try await oathManager.addCredentialFromUri(uri)
            registeredAnyCredential = true
        } catch {
            failures.append("OATH: \(error.localizedDescription)")
        }

        do {
            _ = try await pushManager.addCredentialFromUri(uri)
            registeredAnyCredential = true
        } catch {
            failures.append("Push: \(error.localizedDescription)")
        }

        guard registeredAnyCredential else {
            errorMessage = "Failed to register MFA credential. " + failures.joined(separator: " ")
            isProcessing = false
            return
        }

        successMessage = failures.isEmpty
            ? "MFA credentials registered successfully"
            : "MFA credential registered with partial success"
        isProcessing = false

        // Dismiss after short delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds
        shouldDismiss = true
    }

    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }

    func clearSuccess() {
        successMessage = nil
    }
}
