//
//  AppDelegate.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import UIKit
import UserNotifications
import PingPush

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        // Register for remote notifications unconditionally
        application.registerForRemoteNotifications()

        return true
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            Task { @MainActor in
                if let error = error {
                    DiagnosticLogger.shared.error("Failed to request notification permissions: \(error.localizedDescription)", category: "AppDelegate")
                }

                if granted {
                    DiagnosticLogger.shared.info("Notification permissions granted", category: "AppDelegate")
                } else {
                    DiagnosticLogger.shared.warning("Notification permissions denied", category: "AppDelegate")
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Ensures AppConfiguration is initialized before using PushManager.
    /// This guards against the race condition where the device token arrives
    /// before ContentView.task has run AppConfiguration.shared.initialize().
    private func ensureInitialized() async {
        await AppConfiguration.shared.initialize()
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        DiagnosticLogger.shared.info("APNs Device Token: \(tokenString)", category: "AppDelegate")

        Task {
            do {
                await ensureInitialized()
                try await PushManager.shared.setDeviceToken(tokenString)
                DiagnosticLogger.shared.info("Device token registered with PushManager", category: "AppDelegate")
            } catch {
                DiagnosticLogger.shared.error("Failed to register device token: \(error.localizedDescription)", category: "AppDelegate")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        DiagnosticLogger.shared.error("Failed to register for remote notifications: \(error.localizedDescription)", category: "AppDelegate")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        DiagnosticLogger.shared.info("Received push notification in foreground", category: "AppDelegate")
        DiagnosticLogger.shared.debug("Raw notification userInfo: \(userInfo)", category: "AppDelegate")

        Task {
            do {
                await ensureInitialized()
                if let pushNotification = try await PushManager.shared.processNotification(userInfo: userInfo) {
                    DiagnosticLogger.shared.info("Processed foreground push notification - ID: \(pushNotification.id)", category: "AppDelegate")
                } else {
                    DiagnosticLogger.shared.warning("Foreground notification was not processed (may be unsupported type)", category: "AppDelegate")
                }
            } catch {
                DiagnosticLogger.shared.error("Failed to process foreground push notification: \(error.localizedDescription)", category: "AppDelegate")
            }
        }

        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        DiagnosticLogger.shared.info("Received push notification tap", category: "AppDelegate")
        DiagnosticLogger.shared.debug("Raw notification userInfo: \(userInfo)", category: "AppDelegate")

        Task {
            do {
                await ensureInitialized()
                if let notification = try await PushManager.shared.processNotification(userInfo: userInfo) {
                    DiagnosticLogger.shared.info("Processed push notification successfully - ID: \(notification.id)", category: "AppDelegate")
                    NotificationCenter.default.post(name: .didReceivePushNotification, object: notification)
                } else {
                    DiagnosticLogger.shared.warning("Notification was not processed (may be unsupported type)", category: "AppDelegate")
                }
            } catch {
                DiagnosticLogger.shared.error("Failed to process push notification: \(error.localizedDescription)", category: "AppDelegate")
            }
            completionHandler()
        }
    }
}

// Notification name extension
extension Notification.Name {
    static let didReceivePushNotification = Notification.Name("didReceivePushNotification")
}

