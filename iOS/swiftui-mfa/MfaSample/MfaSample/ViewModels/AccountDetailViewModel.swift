//
//  AccountDetailViewModel.swift
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

/// ViewModel for viewing and editing account details.
@MainActor
class AccountDetailViewModel: ObservableObject {

    // MARK: - Dependencies
    private let oathManager = OathManager.shared
    private let pushManager = PushManager.shared
    private let biometricManager = BiometricManager.shared

    // MARK: - Published State
    @Published var accountGroup: AccountGroup
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var shouldDismiss = false
    @Published var showDeleteConfirmation = false
    @Published var showDeleteTypeSelection = false
    @Published var pendingDeleteType: DeleteType = .both
    @Published var showEditDialog = false

    // MARK: - Computed Properties
    var hasOathCredentials: Bool {
        !accountGroup.oathCredentials.isEmpty
    }

    var hasPushCredentials: Bool {
        !accountGroup.pushCredentials.isEmpty
    }

    // MARK: - Initialization
    init(accountGroup: AccountGroup) {
        self.accountGroup = accountGroup
    }

    // MARK: - Actions

    /// Determines the delete flow based on which credential types exist,
    /// then shows the appropriate dialog.
    func prepareDelete() {
        if hasOathCredentials && hasPushCredentials {
            showDeleteTypeSelection = true
        } else {
            pendingDeleteType = hasOathCredentials ? .oathOnly : .pushOnly
            showDeleteConfirmation = true
        }
    }

    /// Deletes credentials according to `pendingDeleteType`.
    func deleteAccount() async {
        isProcessing = true
        errorMessage = nil

        do {
            switch pendingDeleteType {
            case .oathOnly:
                for credential in accountGroup.oathCredentials {
                    _ = try await oathManager.removeCredential(credential.id)
                }
            case .pushOnly:
                for credential in accountGroup.pushCredentials {
                    _ = try await pushManager.removeCredential(credential.id)
                }
            case .both:
                for credential in accountGroup.oathCredentials {
                    _ = try await oathManager.removeCredential(credential.id)
                }
                for credential in accountGroup.pushCredentials {
                    _ = try await pushManager.removeCredential(credential.id)
                }
            }

            isProcessing = false
            shouldDismiss = true

        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    /// Updates the display names for all credentials in the account group.
    func updateDisplayNames(issuer: String, accountName: String) async {
        do {
            try await oathManager.updateDisplayNames(for: accountGroup.oathCredentials, issuer: issuer, accountName: accountName)
            try await pushManager.updateDisplayNames(for: accountGroup.pushCredentials, issuer: issuer, accountName: accountName)
            accountGroup = AccountGroup(
                issuer: accountGroup.issuer,
                accountName: accountGroup.accountName,
                displayIssuer: issuer,
                displayAccountName: accountName,
                oathCredentials: accountGroup.oathCredentials,
                pushCredentials: accountGroup.pushCredentials
            )
        } catch {
            errorMessage = "Failed to update account: \(error.localizedDescription)"
        }
    }

    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }
}
