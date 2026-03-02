//
//  PushNotificationsViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import PingPush

/// ViewModel for the Push Notifications screen.
@MainActor
class PushNotificationsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let pushManager = PushManager.shared

    // MARK: - Published State
    @Published var selectedTab: NotificationTab = .pending
    @Published var pendingNotifications: [PushNotificationItem] = []
    @Published var allNotifications: [PushNotificationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Enums
    enum NotificationTab: String, CaseIterable {
        case pending = "Pending"
        case all = "All"
    }

    // MARK: - Initialization
    init() {
        setupObservers()
    }

    // MARK: - Setup
    private func setupObservers() {
        // Observe push notification items from PushManager
        pushManager.$pendingNotificationItems
            .receive(on: DispatchQueue.main)
            .assign(to: &$pendingNotifications)

        pushManager.$pushNotificationItems
            .receive(on: DispatchQueue.main)
            .assign(to: &$allNotifications)

        pushManager.$isLoadingNotifications
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }

    // MARK: - Data Loading
    func loadNotifications() async {
        do {
            _ = try await pushManager.loadAllPushNotifications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        await loadNotifications()
    }

    // MARK: - Computed Properties
    var displayedNotifications: [PushNotificationItem] {
        switch selectedTab {
        case .pending:
            return pendingNotifications
        case .all:
            return allNotifications
        }
    }

    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }
}
