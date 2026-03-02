//
//  EditAccountsViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import PingOath
import PingPush

/// ViewModel for reordering, editing, and deleting accounts.
@MainActor
class EditAccountsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let preferences = UserPreferences.shared
    private let oathManager = OathManager.shared
    private let pushManager = PushManager.shared

    // MARK: - Published State
    @Published var accountGroups: [AccountGroup]
    @Published var hasChanges = false
    @Published var errorMessage: String?

    // MARK: - Properties
    private let originalOrder: [String]
    /// Called when the user taps Save, passing the reordered groups so the parent can update its state.
    var onSaveOrder: (([AccountGroup]) -> Void)?

    // MARK: - Initialization
    init(accountGroups: [AccountGroup], onSaveOrder: (([AccountGroup]) -> Void)? = nil) {
        self.accountGroups = accountGroups
        self.originalOrder = accountGroups.map { "\($0.issuer)-\($0.accountName)" }
        self.onSaveOrder = onSaveOrder
    }

    // MARK: - Reordering
    /// Moves an account from one position to another.
    func moveAccount(from source: IndexSet, to destination: Int) {
        var updatedGroups = accountGroups

        let items = source.sorted().map { updatedGroups[$0] }

        for index in source.sorted().reversed() {
            updatedGroups.remove(at: index)
        }

        let firstSourceIndex = source.first ?? 0
        let adjustedDestination = destination > firstSourceIndex ? destination - source.count : destination

        updatedGroups.insert(contentsOf: items, at: adjustedDestination)

        accountGroups = updatedGroups
        checkForChanges()
    }

    /// Saves the new order to UserDefaults and notifies the parent.
    func saveOrder() {
        let newOrder = accountGroups.map { "\($0.issuer)-\($0.accountName)" }
        preferences.setAccountOrder(newOrder)
        onSaveOrder?(accountGroups)
        hasChanges = false
    }

    /// Checks if the current order differs from the original.
    private func checkForChanges() {
        let currentOrder = accountGroups.map { "\($0.issuer)-\($0.accountName)" }
        hasChanges = currentOrder != originalOrder
    }

    /// Resets the order to the original.
    func resetOrder() {
        accountGroups.sort { group1, group2 in
            let key1 = "\(group1.issuer)-\(group1.accountName)"
            let key2 = "\(group2.issuer)-\(group2.accountName)"
            guard let index1 = originalOrder.firstIndex(of: key1),
                  let index2 = originalOrder.firstIndex(of: key2) else {
                return false
            }
            return index1 < index2
        }
        hasChanges = false
    }

    // MARK: - Editing Display Info
    /// Updates the display issuer and display account name for all credentials in a group.
    func updateAccountDisplayInfo(_ group: AccountGroup, displayIssuer: String, displayAccountName: String) async {
        do {
            try await oathManager.updateDisplayNames(for: group.oathCredentials, issuer: displayIssuer, accountName: displayAccountName)
            try await pushManager.updateDisplayNames(for: group.pushCredentials, issuer: displayIssuer, accountName: displayAccountName)
            // Update local state
            if let idx = accountGroups.firstIndex(where: { "\($0.issuer)-\($0.accountName)" == "\(group.issuer)-\(group.accountName)" }) {
                let current = accountGroups[idx]
                accountGroups[idx] = AccountGroup(
                    issuer: current.issuer,
                    accountName: current.accountName,
                    displayIssuer: displayIssuer,
                    displayAccountName: displayAccountName,
                    oathCredentials: current.oathCredentials,
                    pushCredentials: current.pushCredentials
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Deletion
    /// Deletes credentials from a group.
    func deleteAccount(_ group: AccountGroup, deleteOath: Bool, deletePush: Bool) async {
        do {
            if deleteOath {
                for credential in group.oathCredentials {
                    _ = try await oathManager.removeCredential(credential.id)
                }
            }
            if deletePush {
                for credential in group.pushCredentials {
                    _ = try await pushManager.removeCredential(credential.id)
                }
            }
            // Remove or trim the group in local state
            if let idx = accountGroups.firstIndex(where: { "\($0.issuer)-\($0.accountName)" == "\(group.issuer)-\(group.accountName)" }) {
                let current = accountGroups[idx]
                let remainingOath = deleteOath ? [] : current.oathCredentials
                let remainingPush = deletePush ? [] : current.pushCredentials
                if remainingOath.isEmpty && remainingPush.isEmpty {
                    accountGroups.remove(at: idx)
                } else {
                    accountGroups[idx] = AccountGroup(
                        issuer: current.issuer,
                        accountName: current.accountName,
                        displayIssuer: current.displayIssuer,
                        displayAccountName: current.displayAccountName,
                        oathCredentials: remainingOath,
                        pushCredentials: remainingPush
                    )
                }
            }
            checkForChanges()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
