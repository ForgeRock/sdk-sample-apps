//
//  BiometricPromptView.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import LocalAuthentication

/// View for prompting biometric authentication.
struct BiometricPromptView: View {
    let biometricType: LABiometryType
    let onAuthenticate: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            // Icon based on biometric type
            Image(systemName: biometricIcon)
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Instructions
            VStack(spacing: 8) {
                Text("Biometric Verification Required")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Please use \(biometricTypeName) to approve this authentication request.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Authentication prompt
            VStack(spacing: 16) {
                Text("Tap to authenticate")
                    .font(.headline)
                    .foregroundColor(.blue)

                Image(systemName: biometricIcon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .onTapGesture {
                        onAuthenticate()
                    }
            }
            .padding(.vertical, 24)

            // Cancel Button
            Button(action: onCancel) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 32)
    }

    private var biometricIcon: String {
        switch biometricType {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        case .opticID:
            return "opticid"
        case .none:
            return "lock.shield"
        @unknown default:
            return "lock.shield"
        }
    }

    private var biometricTypeName: String {
        switch biometricType {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return "Biometric Authentication"
        @unknown default:
            return "Biometric Authentication"
        }
    }
}

#Preview {
    BiometricPromptView(
        biometricType: .faceID,
        onAuthenticate: {},
        onCancel: {}
    )
}
