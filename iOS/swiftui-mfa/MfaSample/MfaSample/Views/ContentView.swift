//
//  ContentView.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Root view managing navigation for the entire app.
struct ContentView: View {
    @StateObject private var navigationCoordinator = AppNavigationCoordinator()
    @StateObject private var accountsViewModel = AccountsViewModel()
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var appConfiguration = AppConfiguration.shared

    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            // Root screen
            AccountsScreen(
                onScanQrCode: {
                    navigationCoordinator.presentSheet(.qrScanner)
                },
                onManualEntry: {
                    navigationCoordinator.presentSheet(.manualEntry)
                },
                onLogin: {
                    navigationCoordinator.presentSheet(.login)
                },
                onAccountTap: { accountGroup in
                    navigationCoordinator.navigate(to: .accountDetail(accountGroup))
                },
                onPushNotifications: {
                    navigationCoordinator.presentSheet(.pushNotifications)
                },
                onSettings: {
                    navigationCoordinator.presentSheet(.settings)
                },
                onEditAccounts: { accountGroups in
                    navigationCoordinator.presentSheet(.editAccounts(accountGroups))
                },
                onAbout: {
                    navigationCoordinator.navigate(to: .about)
                }
            )
            .navigationDestination(for: NavigationDestination.self) { destination in
                destinationView(for: destination)
            }
        }
        .sheet(item: $navigationCoordinator.presentedSheet) { sheetDestination in
            SheetRouter(destination: sheetDestination)
        }
        .fullScreenCover(item: $navigationCoordinator.presentedFullScreenCover) { coverDestination in
            FullScreenCoverRouter(destination: coverDestination)
        }
        .onChange(of: navigationCoordinator.presentedSheet?.id) { sheetId in
            // Pause TOTP timer while sheets are open to free the main thread
            if sheetId != nil {
                accountsViewModel.pauseTOTPRefresh()
            } else {
                accountsViewModel.resumeTOTPRefresh()
            }
        }
        .environmentObject(navigationCoordinator)
        .environmentObject(accountsViewModel)
        .environmentObject(preferences)
        .environmentObject(appConfiguration)
        .preferredColorScheme(preferences.themeMode.colorScheme)
        .onOpenURL { url in
            navigationCoordinator.handleDeepLink(url)
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceivePushNotification)) { _ in
            navigationCoordinator.presentSheet(.pushNotifications)
        }
        .task {
            // Initialize SDK clients on app startup
            await appConfiguration.initialize()
        }
    }

    // MARK: - Navigation Destination Views

    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .accountDetail(let accountGroup):
            AccountDetailScreen(accountGroup: accountGroup)

        case .diagnosticLogs:
            DiagnosticLogsScreen()

        case .about:
            AboutScreen()

        default:
            // Other destinations are handled via sheets
            EmptyView()
        }
    }

}

// MARK: - Sheet Router
/// Standalone view that routes sheet destinations.
/// Isolated from ContentView's body to avoid re-evaluation when AccountsViewModel publishes changes.
private struct SheetRouter: View {
    let destination: AppNavigationCoordinator.SheetDestination
    @EnvironmentObject private var navigationCoordinator: AppNavigationCoordinator
    @EnvironmentObject private var accountsViewModel: AccountsViewModel

    var body: some View {
        NavigationStack {
            switch destination {
            case .qrScanner:
                QRScannerScreen()

            case .manualEntry:
                ManualEntryScreen()

            case .login:
                LoginScreen()

            case .pushNotifications:
                PushNotificationsScreen(
                    onNotificationTap: { notificationItem in
                        navigationCoordinator.dismissSheet()
                        navigationCoordinator.presentFullScreenCover(.notificationResponse(notificationItem))
                    }
                )

            case .settings:
                SettingsScreen()

            case .editAccounts(let accountGroups):
                EditAccountsScreen(accountGroups: accountGroups, onSaveOrder: { groups in
                    accountsViewModel.updateAccountOrder(groups)
                })
            }
        }
    }
}

// MARK: - Full Screen Cover Router
/// Standalone view that routes full screen cover destinations.
private struct FullScreenCoverRouter: View {
    let destination: AppNavigationCoordinator.FullScreenDestination

    var body: some View {
        NavigationStack {
            switch destination {
            case .notificationResponse(let notificationItem):
                NotificationResponseScreen(notificationItem: notificationItem)
            }
        }
    }
}

#Preview {
    ContentView()
}
