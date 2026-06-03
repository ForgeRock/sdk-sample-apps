// App/AppDelegate.swift
import UIKit
import UserNotifications
import PingOneMFA

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {

    private var pingOneMFACategoryIdentifiers: Set<String> = []

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        application.registerForRemoteNotifications()

        Task {
            await AppConfiguration.shared.initialize()
            let categories = PingOneMFA.getNotificationCategories()
            pingOneMFACategoryIdentifiers = Set(categories.map { $0.identifier })
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

        if pingOneMFACategoryIdentifiers.contains(category) {
            nonisolated(unsafe) let userInfoCopy = userInfo
            Task {
                await AppConfiguration.shared.initialize()
                if let n = try? await PingOneMFA.processRemoteNotification(userInfo: userInfoCopy) {
                    PingOneMFAManager.shared.pendingNotification = n
                }
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

        if pingOneMFACategoryIdentifiers.contains(category) {
            nonisolated(unsafe) let userInfoCopy = userInfo
            Task {
                await AppConfiguration.shared.initialize()
                if let n = try? await PingOneMFA.processRemoteNotificationAction(
                    identifier: actionIdentifier,
                    authenticationMethod: "user",
                    userInfo: userInfoCopy
                ) {
                    PingOneMFAManager.shared.pendingNotification = n
                }
            }
        }
        completionHandler()
    }
}
