//
//  AccountGroupingManager.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOath
import PingPush
import Combine

/// Manager for grouping and organizing credentials into AccountGroups.
@MainActor
class AccountGroupingManager: ObservableObject {
    static let shared = AccountGroupingManager()

    private let userPreferences = UserPreferences.shared

    private init() {}

    /// Groups credentials by issuer and account name based on user preferences.
    /// - Parameters:
    ///   - oathCredentials: List of OATH credentials to group.
    ///   - pushCredentials: List of Push credentials to group.
    ///   - shouldCombine: Whether to combine credentials with the same issuer and account name.
    /// - Returns: Array of AccountGroups.
    func groupCredentialsByAccount(
        oathCredentials: [OathCredential],
        pushCredentials: [PushCredential],
        shouldCombine: Bool? = nil
    ) -> [AccountGroup] {
        let combine = shouldCombine ?? userPreferences.combineAccounts

        if !combine {
            // Create separate account groups for each credential
            return createSeparateGroups(oathCredentials: oathCredentials, pushCredentials: pushCredentials)
        }

        // Combine accounts with the same issuer and account name
        return createCombinedGroups(oathCredentials: oathCredentials, pushCredentials: pushCredentials)
    }

    /// Creates separate AccountGroups for each credential (no combining).
    private func createSeparateGroups(
        oathCredentials: [OathCredential],
        pushCredentials: [PushCredential]
    ) -> [AccountGroup] {
        var groups: [AccountGroup] = []

        // Create individual OATH account groups
        for credential in oathCredentials {
            groups.append(AccountGroup(
                issuer: credential.issuer,
                accountName: credential.accountName,
                displayIssuer: credential.displayIssuer,
                displayAccountName: credential.displayAccountName,
                oathCredentials: [credential],
                pushCredentials: []
            ))
        }

        // Create individual Push account groups
        for credential in pushCredentials {
            groups.append(AccountGroup(
                issuer: credential.issuer,
                accountName: credential.accountName,
                displayIssuer: credential.displayIssuer,
                displayAccountName: credential.displayAccountName,
                oathCredentials: [],
                pushCredentials: [credential]
            ))
        }

        return groups
    }

    /// Creates combined AccountGroups where credentials with the same issuer and account name are grouped together.
    private func createCombinedGroups(
        oathCredentials: [OathCredential],
        pushCredentials: [PushCredential]
    ) -> [AccountGroup] {
        var accountGroups: [String: AccountGroup] = [:]

        // Add OATH credentials to groups
        for credential in oathCredentials {
            let key = "\(credential.issuer)-\(credential.accountName)"
            if let existingGroup = accountGroups[key] {
                // Update existing group
                accountGroups[key] = AccountGroup(
                    issuer: existingGroup.issuer,
                    accountName: existingGroup.accountName,
                    displayIssuer: credential.displayIssuer,
                    displayAccountName: credential.displayAccountName,
                    oathCredentials: existingGroup.oathCredentials + [credential],
                    pushCredentials: existingGroup.pushCredentials
                )
            } else {
                // Create new group
                accountGroups[key] = AccountGroup(
                    issuer: credential.issuer,
                    accountName: credential.accountName,
                    displayIssuer: credential.displayIssuer,
                    displayAccountName: credential.displayAccountName,
                    oathCredentials: [credential],
                    pushCredentials: []
                )
            }
        }

        // Add Push credentials to groups
        for credential in pushCredentials {
            let key = "\(credential.issuer)-\(credential.accountName)"
            if let existingGroup = accountGroups[key] {
                // Update existing group
                accountGroups[key] = AccountGroup(
                    issuer: existingGroup.issuer,
                    accountName: existingGroup.accountName,
                    displayIssuer: credential.displayIssuer,
                    displayAccountName: credential.displayAccountName,
                    oathCredentials: existingGroup.oathCredentials,
                    pushCredentials: existingGroup.pushCredentials + [credential]
                )
            } else {
                // Create new group
                accountGroups[key] = AccountGroup(
                    issuer: credential.issuer,
                    accountName: credential.accountName,
                    displayIssuer: credential.displayIssuer,
                    displayAccountName: credential.displayAccountName,
                    oathCredentials: [],
                    pushCredentials: [credential]
                )
            }
        }

        return Array(accountGroups.values)
    }

    /// Applies saved ordering to account groups.
    /// - Parameter groups: The account groups to order.
    /// - Returns: Ordered account groups.
    func applyOrdering(to groups: [AccountGroup]) -> [AccountGroup] {
        let savedOrder = userPreferences.getAccountOrder()

        if savedOrder.isEmpty {
            return groups
        }

        // Check if we have separate groups (when combine accounts is disabled)
        let hasSeparateGroups = groups.contains { group in
            groups.filter { $0.issuer == group.issuer && $0.accountName == group.accountName }.count > 1
        }

        return hasSeparateGroups
            ? applySeparateGroupOrdering(groups, savedOrder: savedOrder)
            : applyCombinedGroupOrdering(groups, savedOrder: savedOrder)
    }

    /// Applies ordering for separate account groups (when combine accounts is disabled).
    /// Groups OATH and Push cards from the same account together and maintains saved order.
    private func applySeparateGroupOrdering(_ accountGroups: [AccountGroup], savedOrder: [String]) -> [AccountGroup] {
        // Group the separate cards by account (issuer + accountName)
        let groupsByAccount = Dictionary(grouping: accountGroups) { "\($0.issuer)-\($0.accountName)" }

        var orderedList: [AccountGroup] = []
        var processedAccounts = Set<String>()

        // Process accounts in saved order
        for accountKey in savedOrder {
            if let accountCards = groupsByAccount[accountKey], !processedAccounts.contains(accountKey) {
                // Sort cards within account: OATH first, then Push
                let sortedCards = accountCards.sorted { a, b in
                    if !a.oathCredentials.isEmpty && !b.pushCredentials.isEmpty {
                        return true  // OATH first
                    } else if !a.pushCredentials.isEmpty && !b.oathCredentials.isEmpty {
                        return false  // Push second
                    }
                    return false  // Same type, maintain existing order
                }
                orderedList.append(contentsOf: sortedCards)
                processedAccounts.insert(accountKey)
            }
        }

        // Add any new accounts not in saved order
        for (accountKey, accountCards) in groupsByAccount {
            if !processedAccounts.contains(accountKey) {
                let sortedCards = accountCards.sorted { a, b in
                    if !a.oathCredentials.isEmpty && !b.pushCredentials.isEmpty {
                        return true
                    } else if !a.pushCredentials.isEmpty && !b.oathCredentials.isEmpty {
                        return false
                    }
                    return false
                }
                orderedList.append(contentsOf: sortedCards)
            }
        }

        return orderedList
    }

    /// Applies ordering for combined account groups (when combine accounts is enabled).
    private func applyCombinedGroupOrdering(_ accountGroups: [AccountGroup], savedOrder: [String]) -> [AccountGroup] {
        // Create a map for quick lookup
        let accountMap = Dictionary(uniqueKeysWithValues: accountGroups.map { ("\($0.issuer)-\($0.accountName)", $0) })

        var orderedList: [AccountGroup] = []
        var addedKeys = Set<String>()

        // Add accounts in saved order
        for key in savedOrder {
            if let accountGroup = accountMap[key], !addedKeys.contains(key) {
                orderedList.append(accountGroup)
                addedKeys.insert(key)
            }
        }

        // Add any new accounts that weren't in the saved order
        for accountGroup in accountGroups {
            let key = "\(accountGroup.issuer)-\(accountGroup.accountName)"
            if !addedKeys.contains(key) {
                orderedList.append(accountGroup)
            }
        }

        return orderedList
    }

    /// Saves the current order of account groups.
    /// - Parameter groups: The ordered account groups.
    func saveOrdering(for groups: [AccountGroup]) {
        let order = groups.map { "\($0.issuer)-\($0.accountName)" }
        userPreferences.setAccountOrder(order)
    }
}
