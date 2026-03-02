//
//  QRScannerScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import AVFoundation

/// Screen for scanning QR codes to register MFA credentials.
struct QRScannerScreen: View {
    @StateObject private var viewModel = QRScannerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Camera view
            if viewModel.cameraPermissionStatus == .authorized {
                QRCodeScanner(
                    onCodeScanned: { code in
                        Task {
                            await viewModel.handleScannedCode(code)
                        }
                    },
                    onError: { error in
                        viewModel.errorMessage = error.localizedDescription
                    }
                )
                .ignoresSafeArea()

                // Scanning overlay
                VStack {
                    Spacer()

                    // Instructions
                    VStack(spacing: 12) {
                        Text("Scan QR Code")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Position the QR code within the frame")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()

                    Spacer()
                }
            } else if viewModel.cameraPermissionStatus == .denied {
                // Permission denied view
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Camera Access Required")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Please enable camera access in Settings to scan QR codes.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                // Requesting permission
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Requesting camera access...")
                        .foregroundColor(.secondary)
                }
            }

            // Processing overlay
            if viewModel.isProcessing {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)

                        Text("Registering credential...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
        .navigationTitle("Scan QR Code")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .alert("Success", isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.clearSuccess() } }
        )) {
            Button("OK") {
                viewModel.clearSuccess()
                dismiss()
            }
        } message: {
            if let success = viewModel.successMessage {
                Text(success)
            }
        }
        .task {
            if viewModel.cameraPermissionStatus == .notDetermined {
                await viewModel.requestCameraPermission()
            }
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        QRScannerScreen()
    }
}
