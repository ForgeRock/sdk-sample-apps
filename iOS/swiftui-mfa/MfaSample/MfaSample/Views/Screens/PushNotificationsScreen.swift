//
//  PushNotificationsScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Screen displaying push notifications with pending and all tabs.
struct PushNotificationsScreen: View {
    @StateObject private var viewModel = PushNotificationsViewModel()

    // Navigation callback
    let onNotificationTap: (PushNotificationItem) -> Void

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.displayedNotifications.isEmpty {
                // Initial loading
                ProgressView("Loading notifications...")
            } else if viewModel.displayedNotifications.isEmpty {
                // Empty state
                EmptyStateView(
                    icon: viewModel.selectedTab == .pending ? "bell.slash" : "tray",
                    title: viewModel.selectedTab == .pending ? "No Pending Notifications" : "No Notifications",
                    message: viewModel.selectedTab == .pending ?
                        "You don't have any pending push notifications at the moment." :
                        "You don't have any push notifications yet.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                // Notifications list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.displayedNotifications) { item in
                            PushNotificationCard(
                                item: item,
                                onTap: {
                                    onNotificationTap(item)
                                }
                            )
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Push Notifications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("View", selection: $viewModel.selectedTab) {
                    ForEach(PushNotificationsViewModel.NotificationTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
    }
}

#Preview {
    NavigationView {
        PushNotificationsScreen(onNotificationTap: { _ in })
    }
}
