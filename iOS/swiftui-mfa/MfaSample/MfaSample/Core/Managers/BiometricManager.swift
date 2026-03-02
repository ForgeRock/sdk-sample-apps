//
//  BiometricManager.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import LocalAuthentication
import Combine

/// Manager for handling biometric authentication (Face ID / Touch ID).
@MainActor
class BiometricManager: ObservableObject {
    static let shared = BiometricManager()

    @Published var biometricType: BiometricType = .none
    @Published var isAvailable: Bool = false

    private init() {
        checkBiometricAvailability()
    }

    /// Enum representing the available biometric authentication types.
    enum BiometricType {
        case none
        case faceID
        case touchID
        case opticID

        var displayName: String {
            switch self {
            case .none:
                return "None"
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            case .opticID:
                return "Optic ID"
            }
        }

        var iconName: String {
            switch self {
            case .none:
                return "nosign"
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            case .opticID:
                return "opticid"
            }
        }
    }

    /// Check if biometric authentication is available on the device.
    func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?

        isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        if isAvailable {
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .opticID:
                biometricType = .opticID
            case .none:
                biometricType = .none
                isAvailable = false
            @unknown default:
                biometricType = .none
                isAvailable = false
            }
        } else {
            biometricType = .none
        }
    }

    /// Authenticate using biometric authentication.
    /// - Parameter reason: The reason to display to the user.
    /// - Returns: True if authentication was successful.
    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                throw AppError.biometricError(error.localizedDescription)
            }
            throw AppError.biometricError("Biometric authentication is not available")
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .userFallback, .systemCancel, .appCancel:
                throw AppError.biometricError("Authentication was cancelled")
            case .biometryNotAvailable:
                throw AppError.biometricError("Biometric authentication is not available")
            case .biometryNotEnrolled:
                throw AppError.biometricError("Biometric authentication is not enrolled")
            case .biometryLockout:
                throw AppError.biometricError("Biometric authentication is locked. Please try again later")
            default:
                throw AppError.biometricError(error.localizedDescription)
            }
        }
    }

    /// Authenticate using device passcode if biometric fails.
    /// - Parameter reason: The reason to display to the user.
    /// - Returns: True if authentication was successful.
    func authenticateWithPasscode(reason: String) async throws -> Bool {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            throw AppError.biometricError(error.localizedDescription)
        }
    }
}
