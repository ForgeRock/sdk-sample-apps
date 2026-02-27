//
//  PushManager.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingPush
import Combine

/// Manager class for handling all Push credential and notification operations.
/// Encapsulates Push-specific business logic and state management.
@MainActor
class PushManager: ObservableObject {
    static let shared = PushManager()

    private var pushClient: PushClient?

    @Published var pushCredentials: [PushCredential] = []
    @Published var isLoadingCredentials: Bool = false
    @Published var pushNotifications: [PushNotification] = []
    @Published var pendingNotifications: [PushNotification] = []
    @Published var isLoadingNotifications: Bool = false
    @Published var pushNotificationItems: [PushNotificationItem] = []
    @Published var pendingNotificationItems: [PushNotificationItem] = []
    @Published var lastAddedCredential: PushCredential?

    private var deviceToken: String?

    private init() {}

    /// Sets the Push client instance.
    /// - Parameter client: The PushClient to use.
    func setClient(_ client: PushClient) {
        self.pushClient = client
    }

    /// Sets the device token for push notifications.
    /// - Parameters:
    ///   - token: The APNs device token.
    ///   - credentialId: Optional credential ID to associate with the token.
    func setDeviceToken(_ token: String, credentialId: String? = nil) async throws {
        self.deviceToken = token
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            _ = try await Task.detached(priority: .userInitiated) {
                try await client.setDeviceToken(token, credentialId: credentialId)
            }.value
        } catch {
            throw AppError.pushError("Failed to set device token: \(error.localizedDescription)")
        }
    }

    /// Loads all Push credentials from the SDK.
    /// - Returns: Array of Push credentials.
    func loadCredentials() async throws -> [PushCredential] {
        guard let client = pushClient else {
            // Client not initialized yet - return empty array without error
            self.pushCredentials = []
            updateNotificationItems()
            return []
        }

        isLoadingCredentials = true
        defer { isLoadingCredentials = false }

        do {
            let credentials = try await Task.detached(priority: .userInitiated) {
                try await client.getCredentials()
            }.value
            self.pushCredentials = credentials
            updateNotificationItems()
            return credentials
        } catch {
            throw AppError.pushError("Failed to load credentials: \(error.localizedDescription)")
        }
    }

    /// Adds a Push credential from a URI.
    /// - Parameter uri: The pushauth:// or mfauth:// URI string.
    /// - Returns: The created PushCredential.
    func addCredentialFromUri(_ uri: String) async throws -> PushCredential {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let credential = try await Task.detached(priority: .userInitiated) {
                try await client.addCredentialFromUri(uri)
            }.value
            self.lastAddedCredential = credential
            // Reload credentials to refresh the list
            _ = try await loadCredentials()
            return credential
        } catch {
            throw AppError.pushError("Failed to add credential: \(error.localizedDescription)")
        }
    }

    /// Removes a Push credential from the SDK.
    /// - Parameter credentialId: The ID of the credential to remove.
    /// - Returns: True if the credential was removed.
    func removeCredential(_ credentialId: String) async throws -> Bool {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let removed = try await Task.detached(priority: .userInitiated) {
                try await client.deleteCredential(credentialId: credentialId)
            }.value
            if removed {
                // Reload credentials to refresh the list
                _ = try await loadCredentials()
            }
            return removed
        } catch {
            throw AppError.pushError("Failed to remove credential: \(error.localizedDescription)")
        }
    }

    /// Updates a Push credential in the SDK.
    /// - Parameter credential: The credential to update.
    /// - Returns: The updated credential.
    func updateCredential(_ credential: PushCredential) async throws -> PushCredential {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let updated = try await Task.detached(priority: .userInitiated) {
                try await client.saveCredential(credential)
            }.value
            // Reload credentials to refresh the list
            _ = try await loadCredentials()
            return updated
        } catch {
            throw AppError.pushError("Failed to update credential: \(error.localizedDescription)")
        }
    }

    /// Updates the display names on a batch of Push credentials.
    /// - Parameters:
    ///   - credentials: The credentials to update.
    ///   - issuer: The new display issuer string.
    ///   - accountName: The new display account name string.
    func updateDisplayNames(for credentials: [PushCredential], issuer: String, accountName: String) async throws {
        for credential in credentials {
            var updated = credential
            updated.displayIssuer = issuer
            updated.displayAccountName = accountName
            _ = try await updateCredential(updated)
        }
    }

    /// Loads all push notifications (not just pending ones).
    /// - Returns: Array of all push notifications.
    func loadAllPushNotifications() async throws -> [PushNotification] {
        guard let client = pushClient else {
            // Client not initialized yet - return empty array without error
            self.pushNotifications = []
            self.pendingNotifications = []
            updateNotificationItems()
            return []
        }

        isLoadingNotifications = true
        defer { isLoadingNotifications = false }

        do {
            let allNotifications = try await Task.detached(priority: .userInitiated) {
                try await client.getAllNotifications()
            }.value
            let pending = allNotifications.filter { $0.pending && !$0.isExpired }
            self.pushNotifications = allNotifications
            self.pendingNotifications = pending
            updateNotificationItems()
            return allNotifications
        } catch {
            throw AppError.pushError("Failed to load all notifications: \(error.localizedDescription)")
        }
    }

    /// Approves a push notification.
    /// - Parameter notificationId: The ID of the notification to approve.
    /// - Returns: True if approval was successful.
    func approveNotification(_ notificationId: String) async throws -> Bool {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let success = try await Task.detached(priority: .userInitiated) {
                try await client.approveNotification(notificationId)
            }.value
            if success {
                // Reload notifications after approving
                _ = try? await loadAllPushNotifications()
            }
            return success
        } catch {
            throw AppError.pushError("Failed to approve notification: \(error.localizedDescription)")
        }
    }

    /// Approves a push notification with a challenge response.
    /// - Parameters:
    ///   - notificationId: The ID of the notification to approve.
    ///   - challengeResponse: The challenge response string.
    /// - Returns: True if approval was successful.
    func approveChallengeNotification(_ notificationId: String, challengeResponse: String) async throws -> Bool {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let success = try await Task.detached(priority: .userInitiated) {
                try await client.approveChallengeNotification(notificationId, challengeResponse: challengeResponse)
            }.value
            if success {
                // Reload notifications after approving
                _ = try? await loadAllPushNotifications()
            }
            return success
        } catch {
            throw AppError.pushError("Failed to approve challenge notification: \(error.localizedDescription)")
        }
    }

    /// Denies a push notification.
    /// - Parameter notificationId: The ID of the notification to deny.
    /// - Returns: True if denial was successful.
    func denyNotification(_ notificationId: String) async throws -> Bool {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let success = try await Task.detached(priority: .userInitiated) {
                try await client.denyNotification(notificationId)
            }.value
            if success {
                // Reload notifications after denying
                _ = try? await loadAllPushNotifications()
            }
            return success
        } catch {
            throw AppError.pushError("Failed to deny notification: \(error.localizedDescription)")
        }
    }

    /// Cleans up old notifications.
    /// - Returns: Number of notifications cleaned up.
    func cleanupNotifications() async throws -> Int {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let count = try await Task.detached(priority: .userInitiated) {
                try await client.cleanupNotifications()
            }.value
            // Reload notifications after cleanup
            _ = try? await loadAllPushNotifications()
            return count
        } catch {
            throw AppError.pushError("Failed to cleanup notifications: \(error.localizedDescription)")
        }
    }

    /// Process a push notification received from APNs.
    /// - Parameter userInfo: The notification payload.
    /// - Returns: The processed PushNotification.
    func processNotification(userInfo: [AnyHashable: Any]) async throws -> PushNotification? {
        guard let client = pushClient else {
            throw AppError.pushError("Push client not initialized")
        }

        do {
            let notification = try await Task.detached(priority: .userInitiated) {
                try await client.processNotification(userInfo: userInfo)
            }.value
            // Reload notifications after processing
            _ = try? await loadAllPushNotifications()
            return notification
        } catch {
            throw AppError.pushError("Failed to process notification: \(error.localizedDescription)")
        }
    }

    /// Clears the last added Push credential.
    func clearLastAddedCredential() {
        lastAddedCredential = nil
    }

    /// Updates notification items for UI display.
    private func updateNotificationItems() {
        // Convert all notifications to UI items
        pushNotificationItems = pushNotifications.map { notification in
            createPushNotificationItem(notification: notification)
        }

        // Convert pending notifications to UI items
        pendingNotificationItems = pendingNotifications.map { notification in
            createPushNotificationItem(notification: notification)
        }
    }

    /// Creates a PushNotificationItem from a PushNotification.
    private func createPushNotificationItem(notification: PushNotification) -> PushNotificationItem {
        let credential = pushCredentials.first { $0.id == notification.credentialId }

        // Determine notification characteristics
        let pushTypeStr = String(describing: notification.pushType).lowercased()
        let requiresChallenge = pushTypeStr.contains("challenge")
        let requiresBiometric = pushTypeStr.contains("biometric")

        // Determine notification status
        let status: NotificationStatus
        if notification.approved {
            status = .approved
        } else if notification.isExpired && notification.pending {
            status = .expired
        } else if notification.pending {
            status = .pending
        } else {
            status = .denied
        }

        // TODO: Parse context info for location and device info in later phases

        return PushNotificationItem(
            notification: notification,
            credential: credential,
            timeAgo: "", // TODO: Calculate time ago string
            requiresChallenge: requiresChallenge,
            requiresBiometric: requiresBiometric,
            hasLocationInfo: false,
            latitude: nil,
            longitude: nil,
            status: status,
            deviceInfo: nil
        )
    }

    /// Closes the Push client and releases resources.
    func close() async {
        await pushClient?.close()
    }
}
