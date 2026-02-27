//
//  PushNotificationItem.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingPush

/// Enum representing the status of a push notification.
enum NotificationStatus {
    case pending
    case approved
    case denied
    case expired
}

/// Data structure for push notification UI display with additional UI-specific fields.
struct PushNotificationItem: Identifiable {
    let id = UUID()
    let notification: PushNotification
    let credential: PushCredential?
    let timeAgo: String
    let requiresChallenge: Bool
    let requiresBiometric: Bool
    let hasLocationInfo: Bool
    let latitude: Double?
    let longitude: Double?
    let status: NotificationStatus
    let deviceInfo: DeviceInfo?

    init(
        notification: PushNotification,
        credential: PushCredential? = nil,
        timeAgo: String = "",
        requiresChallenge: Bool = false,
        requiresBiometric: Bool = false,
        hasLocationInfo: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        status: NotificationStatus = .pending,
        deviceInfo: DeviceInfo? = nil
    ) {
        self.notification = notification
        self.credential = credential
        self.timeAgo = timeAgo
        self.requiresChallenge = requiresChallenge
        self.requiresBiometric = requiresBiometric
        self.hasLocationInfo = hasLocationInfo
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.deviceInfo = deviceInfo
    }
}

/// Data structure to hold parsed user agent information.
struct DeviceInfo {
    let userAgent: String
    let browser: String?
    let os: String?
    let browserVersion: String?
}

/// Data structure for location information.
struct LocationData: Codable {
    let latitude: Double
    let longitude: Double
}

/// Wrapper for context information from push notifications.
struct ContextWrapper: Codable {
    let location: LocationData?
    let remoteIp: String?
    let userAgent: String?
}

/// Data structure with simplified address data for UI display.
struct LocationAddress {
    let city: String
    let state: String
    let country: String

    func formatForDisplay() -> String {
        return "\(city), \(state), \(country)"
    }
}
