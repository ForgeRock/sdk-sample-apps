//
//  NavigationDestination.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Enumeration of all possible navigation destinations in the app.
enum NavigationDestination: Hashable {
    // Main screens
    case accounts
    case qrScanner
    case manualEntry
    case login

    // Account management
    case accountDetail(AccountGroup)
    case editAccounts([AccountGroup])

    // Push notifications
    case pushNotifications
    case notificationResponse(PushNotificationItem)

    // Settings and info
    case settings
    case diagnosticLogs
    case about

    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        switch self {
        case .accounts:
            hasher.combine("accounts")
        case .qrScanner:
            hasher.combine("qrScanner")
        case .manualEntry:
            hasher.combine("manualEntry")
        case .login:
            hasher.combine("login")
        case .accountDetail(let group):
            hasher.combine("accountDetail")
            hasher.combine(group.id)
        case .editAccounts:
            hasher.combine("editAccounts")
        case .pushNotifications:
            hasher.combine("pushNotifications")
        case .notificationResponse(let item):
            hasher.combine("notificationResponse")
            hasher.combine(item.id)
        case .settings:
            hasher.combine("settings")
        case .diagnosticLogs:
            hasher.combine("diagnosticLogs")
        case .about:
            hasher.combine("about")
        }
    }

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.accounts, .accounts),
             (.qrScanner, .qrScanner),
             (.manualEntry, .manualEntry),
             (.login, .login),
             (.pushNotifications, .pushNotifications),
             (.settings, .settings),
             (.diagnosticLogs, .diagnosticLogs),
             (.about, .about),
             (.editAccounts, .editAccounts):
            return true
        case (.accountDetail(let lhsGroup), .accountDetail(let rhsGroup)):
            return lhsGroup.id == rhsGroup.id
        case (.notificationResponse(let lhsItem), .notificationResponse(let rhsItem)):
            return lhsItem.id == rhsItem.id
        default:
            return false
        }
    }
}
