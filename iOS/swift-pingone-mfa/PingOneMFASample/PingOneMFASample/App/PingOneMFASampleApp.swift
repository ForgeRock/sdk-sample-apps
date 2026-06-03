// App/PingOneMFASampleApp.swift
import SwiftUI

@main
struct PingOneMFASampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let coordinator = AppNavigationCoordinator()
    private let manager = PingOneMFAManager.shared
    private let appConfig = AppConfiguration.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $coordinator.path) {
                AccountsScreen()
            }
            .environmentObject(coordinator)
            .environmentObject(manager)
            .environmentObject(appConfig)
            .task {
                await appConfig.initialize()
            }
        }
    }
}
