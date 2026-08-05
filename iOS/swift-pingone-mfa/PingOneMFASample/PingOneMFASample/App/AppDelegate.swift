// App/AppDelegate.swift
import UIKit
import UserNotifications
import PingOneMFA

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        application.registerForRemoteNotifications()

        Task {
            let categories = await sdkNotificationCategories()
            let existing = await UNUserNotificationCenter.current().notificationCategories()
            UNUserNotificationCenter.current().setNotificationCategories(existing.union(categories))
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Task {
            await AppConfiguration.shared.initialize()
            try? await PingOneMFA.setDeviceToken(deviceToken)
        }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("[AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let category = notification.request.content.categoryIdentifier

        nonisolated(unsafe) let userInfoCopy = userInfo
        Task {
            if let n = try? await PingOneMFA.processRemoteNotification(userInfo: userInfoCopy) {
                PingOneMFAManager.shared.pendingNotification = n
            }
        }
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping @Sendable () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let category = response.notification.request.content.categoryIdentifier
        let actionIdentifier = response.actionIdentifier

        nonisolated(unsafe) let userInfoCopy = userInfo
        Task {
            if let n = try? await PingOneMFA.processRemoteNotificationAction(
                identifier: actionIdentifier,
                authenticationMethod: "user",
                userInfo: userInfoCopy
            ) {
                PingOneMFAManager.shared.pendingNotification = n
            }
        }
        completionHandler()
    }

    // MARK: - Private

    /// Initializes the SDK if needed, then returns its notification categories.
    /// Returns an empty set when initialization fails.
    private func sdkNotificationCategories() async -> Set<UNNotificationCategory> {
        await AppConfiguration.shared.initialize()
        guard AppConfiguration.shared.isInitialized else { return [] }
        return PingOneMFA.getNotificationCategories()
    }
}
