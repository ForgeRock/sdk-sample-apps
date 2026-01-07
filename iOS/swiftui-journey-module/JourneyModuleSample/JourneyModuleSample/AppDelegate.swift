//
//  AppDelegate.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import UIKit
import PingOidc
import PingJourney
import PingOath
import PingPush
import PingLogger

/// AppDelegate to handle push notifications
/// - Note: Ensure that `PushClient` is initialized in `ConfigurationManager` before processing notifications.
@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {

    // MFA Clients
    public var oathClient: OathClient?
    public var pushClient: PushClient?
    
    // MFA Services
    public var oathTimerService: OathTimerService?
    
    // Thread safety - use actor for initialization synchronization
    private let initActor = ClientInitializationActor()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permissions
        requestNotificationPermissions()

        // Register for remote notifications
        application.registerForRemoteNotifications()

        return true
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Failed to request notification permissions: \(error.localizedDescription)")
            }

            if granted {
                print("Notification permissions granted")
            } else {
                print("Notification permissions denied")
            }
        }
    }

    // MARK: - Helper Methods

    /// Ensures PushClient is initialized and returns it
    /// - Returns: Initialized PushClient instance
    /// - Throws: Error if initialization fails
    private func getInitializedPushClient() async throws -> PushClient {
        if pushClient == nil {
            try await initializePushClient()
        }

        guard let client = pushClient else {
            throw NSError(
                domain: "AppDelegate",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to initialize PushClient"]
            )
        }

        return client
    }

    // MARK: - Remote Notification Registration

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs Device Token: \(tokenString)")

        // Store device token in PushClient
        Task {
            do {
                let client = try await getInitializedPushClient()
                _ = try await client.setDeviceToken(tokenString)
                print("Device token registered with PushClient")
            } catch {
                print("Failed to register device token: \(error.localizedDescription)")
            }
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Received push notification in foreground")
        print("Raw notification userInfo: \(userInfo)")

        // Process the notification through PushClient
        Task {
            do {
                let client = try await getInitializedPushClient()

                // Process the notification - PushClient automatically extracts APNs payload
                if let pushNotification = try await client.processNotification(userInfo: userInfo) {
                    print("Processed foreground push notification - ID: \(pushNotification.id), MessageID: \(pushNotification.messageId)")
                } else {
                    print("Foreground notification was not processed (may be unsupported type)")
                }
            } catch {
                print("Failed to process foreground push notification: \(error.localizedDescription)")
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
        print("Received push notification tap")
        print("Raw notification userInfo: \(userInfo)")

        // Process the notification through PushClient
        Task {
            do {
                let client = try await getInitializedPushClient()

                // Process the notification - PushClient automatically extracts APNs payload
                if let notification = try await client.processNotification(userInfo: userInfo) {
                    print("Processed push notification successfully - ID: \(notification.id), MessageID: \(notification.messageId)")
                    
                    // Navigate to Push Notifications view
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NavigateToPushNotifications"),
                        object: nil
                    )
                } else {
                    print("Notification was not processed (may be unsupported type)")
                }
            } catch {
                print("Failed to process push notification: \(error.localizedDescription)")
            }
        }

        completionHandler()
    }
    
    // MARK: - MFA Client Initialization

    /// Initialize the OATH client for MFA functionality
    public func initializeOathClient() async throws {
        let client = try await initActor.initializeOath {
            try await OathClient.createClient { config in
                config.logger = LogManager.logger
            }
        }
        
        if let client = client {
            self.oathClient = client
            
            // Initialize the timer service with the client
            await MainActor.run {
                oathTimerService = OathTimerService(client: client)
            }
        }
    }

    /// Initialize the Push client for MFA functionality
    public func initializePushClient() async throws {
        let client = try await initActor.initializePush {
            try await PushClient.createClient { config in
                config.logger = LogManager.logger
            }
        }
        
        if let client = client {
            self.pushClient = client
        }
    }
}

// MARK: - Actor for Thread-Safe Initialization

private actor ClientInitializationActor {
    private var isOathInitializing = false
    private var isPushInitializing = false
    private var oathInitialized = false
    private var pushInitialized = false
    
    func initializeOath(factory: @Sendable () async throws -> OathClient) async throws -> OathClient? {
        guard !oathInitialized && !isOathInitializing else { return nil }
        
        isOathInitializing = true
        defer { isOathInitializing = false }
        
        let client = try await factory()
        oathInitialized = true
        return client
    }
    
    func initializePush(factory: @Sendable () async throws -> PushClient) async throws -> PushClient? {
        guard !pushInitialized && !isPushInitializing else { return nil }
        
        isPushInitializing = true
        defer { isPushInitializing = false }
        
        let client = try await factory()
        pushInitialized = true
        return client
    }
}

//Extensions
extension ObservableObject {
    @MainActor
    var topViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = keyWindow.rootViewController else {
            return nil
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

extension Binding {
    func toUnwrapped<T: Sendable>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
