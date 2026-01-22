//
//  AppNavigationCoordinator.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import Combine

/// Central navigation coordinator managing the app's navigation state.
@MainActor
class AppNavigationCoordinator: ObservableObject {
    // MARK: - Published State
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreenCover: FullScreenDestination?

    // MARK: - Sheet Destinations
    enum SheetDestination: Identifiable {
        case qrScanner
        case manualEntry
        case login
        case pushNotifications
        case settings
        case editAccounts([AccountGroup])

        var id: String {
            switch self {
            case .qrScanner: return "qrScanner"
            case .manualEntry: return "manualEntry"
            case .login: return "login"
            case .pushNotifications: return "pushNotifications"
            case .settings: return "settings"
            case .editAccounts: return "editAccounts"
            }
        }
    }

    // MARK: - Full Screen Cover Destinations
    enum FullScreenDestination: Identifiable {
        case notificationResponse(PushNotificationItem)

        var id: String {
            switch self {
            case .notificationResponse(let item): return "notificationResponse-\(item.id)"
            }
        }
    }

    // MARK: - Navigation Methods

    /// Navigates to a destination using the navigation stack
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }

    /// Presents a sheet
    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    /// Presents a full screen cover
    func presentFullScreenCover(_ destination: FullScreenDestination) {
        presentedFullScreenCover = destination
    }

    /// Dismisses the currently presented sheet
    func dismissSheet() {
        presentedSheet = nil
    }

    /// Dismisses the currently presented full screen cover
    func dismissFullScreenCover() {
        presentedFullScreenCover = nil
    }

    /// Pops the navigation stack to the previous screen
    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    /// Pops to the root of the navigation stack
    func popToRoot() {
        path = NavigationPath()
    }

    // MARK: - Deep Linking Support

    /// Handles deep link URLs (otpauth://, pushauth://, mfauth://)
    func handleDeepLink(_ url: URL) {
        // Deep link handling will trigger appropriate navigation
        // This is called from AppDelegate or onOpenURL
        let scheme = url.scheme?.lowercased() ?? ""

        switch scheme {
        case "otpauth", "pushauth", "mfauth":
            // These URIs should trigger QR Scanner screen for processing
            presentSheet(.qrScanner)

        default:
            break
        }
    }

    /// Handles navigation from push notifications
    func handleNotification(_ notificationId: String) {
        // Navigate to push notifications screen and potentially to specific notification
        presentSheet(.pushNotifications)
    }
}
