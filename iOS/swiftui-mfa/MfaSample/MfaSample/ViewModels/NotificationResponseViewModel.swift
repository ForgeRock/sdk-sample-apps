//
//  NotificationResponseViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import LocalAuthentication
import PingPush

/// ViewModel for responding to push notifications.
@MainActor
class NotificationResponseViewModel: ObservableObject {
    // MARK: - Dependencies
    private let pushManager = PushManager.shared
    private let biometricManager = BiometricManager.shared

    // MARK: - Published State
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var shouldDismiss = false
    @Published var showBiometricPrompt = false

    // MARK: - Properties
    let notificationItem: PushNotificationItem

    // MARK: - Initialization
    init(notificationItem: PushNotificationItem) {
        self.notificationItem = notificationItem
    }

    // MARK: - Notification Response
    /// Approves the push notification.
    func approve(challengeResponse: String? = nil) async {
        // For BIOMETRIC type, check if biometrics are available
        if notificationItem.notification.pushType == .biometric {
            if biometricManager.biometricType == .none {
                errorMessage = "Biometric authentication is not available on this device"
                return
            }

            // Prompt for biometric authentication
            do {
                let authenticated = try await biometricManager.authenticate(reason: "Approve authentication request")
                if !authenticated {
                    errorMessage = "Biometric authentication failed"
                    return
                }
            } catch {
                errorMessage = "Biometric authentication error: \(error.localizedDescription)"
                return
            }
        }

        // Proceed with approval
        isProcessing = true
        errorMessage = nil

        do {
            // Use appropriate approval method based on challenge response
            if let challenge = challengeResponse {
                _ = try await pushManager.approveChallengeNotification(
                    notificationItem.notification.id,
                    challengeResponse: challenge
                )
            } else {
                _ = try await pushManager.approveNotification(notificationItem.notification.id)
            }

            isProcessing = false

            // Dismiss after short delay
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            shouldDismiss = true

        } catch {
            errorMessage = "Failed to approve notification: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    /// Denies the push notification.
    func deny() async {
        isProcessing = true
        errorMessage = nil

        do {
            _ = try await pushManager.denyNotification(notificationItem.notification.id)

            isProcessing = false

            // Dismiss after short delay
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            shouldDismiss = true

        } catch {
            errorMessage = "Failed to deny notification: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }

    var biometricType: LABiometryType {
        switch biometricManager.biometricType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            if #available(iOS 17.0, *) {
                return .opticID
            } else {
                return .none
            }
        case .none:
            return .none
        }
    }
}
