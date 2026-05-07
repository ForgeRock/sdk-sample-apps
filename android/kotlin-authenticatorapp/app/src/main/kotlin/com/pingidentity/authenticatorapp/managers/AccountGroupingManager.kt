/*
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.authenticatorapp.managers

import com.pingidentity.authenticatorapp.data.AccountGroup
import com.pingidentity.authenticatorapp.data.DiagnosticLogger
import com.pingidentity.authenticatorapp.data.UserPreferences
import com.pingidentity.authenticatorapp.data.groupCredentialsByAccount
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import com.pingidentity.mfa.oath.OathCredential
import com.pingidentity.mfa.push.PushCredential

/**
 * Manager class for handling account grouping logic and account ordering.
 * Encapsulates the business logic for combining and organizing account groups.
 *
 * @param userPreferences UserPreferences dependency for settings management
 * @param diagnosticLogger DiagnosticLogger for logging
 */
class AccountGroupingManager(
    private val userPreferences: UserPreferences,
    private val diagnosticLogger: DiagnosticLogger
) {
    
    private val _accountGroups = MutableStateFlow<List<AccountGroup>>(emptyList())
    val accountGroups: StateFlow<List<AccountGroup>> = _accountGroups.asStateFlow()

    /**
     * Updates the account groups based on current credentials and user preferences.
     */
    fun updateAccountGroups(
        oathCredentials: List<OathCredential>,
        pushCredentials: List<PushCredential>
    ) {
        val shouldCombine = userPreferences.isCombineAccountsEnabled()
        diagnosticLogger.d("updateAccountGroups: shouldCombine=$shouldCombine")
        
        // Skip update if we have no data to avoid unnecessary recomposition
        if (oathCredentials.isEmpty() && pushCredentials.isEmpty()) {
            diagnosticLogger.d("Skipping account group update - no credentials loaded yet")
            return
        }

        val newAccountGroups = groupCredentialsByAccount(
            oathCredentials, pushCredentials, shouldCombine
        )
        
        // Apply saved account order
        val orderedAccountGroups = applyAccountOrder(newAccountGroups)
        
        // Debug logging to help identify duplicate group issues
        diagnosticLogger.d("updateAccountGroups: shouldCombine=$shouldCombine, " +
                "oathCredentials=${oathCredentials.size}, " +
                "pushCredentials=${pushCredentials.size}, " +
                "resultingGroups=${orderedAccountGroups.size}")
        
        // Validate that we don't have duplicate account groups with the same issuer+account name
        val groupKeys = orderedAccountGroups.map { "${it.issuer}-${it.accountName}" }
        val duplicateKeys = groupKeys.groupBy { it }.filter { it.value.size > 1 }.keys
        if (duplicateKeys.isNotEmpty()) {
            diagnosticLogger.w("Warning: Found duplicate account groups with keys: $duplicateKeys")
            // This is expected when shouldCombine is false and there are multiple credentials
            // for the same account, but worth logging for debugging
        }

        _accountGroups.value = orderedAccountGroups
    }

    /**
     * Updates the account group order immediately.
     * This provides immediate feedback while the order is being persisted.
     */
    fun updateAccountGroupOrder(newAccountGroups: List<AccountGroup>) {
        diagnosticLogger.d("Update AccountGroupOrder")
        _accountGroups.value = newAccountGroups
    }

    /**
     * Save the current account order to preferences.
     */
    suspend fun saveAccountOrder(accountGroups: List<AccountGroup>) {
        val orderKeys = accountGroups.map { "${it.issuer}-${it.accountName}" }
        userPreferences.setAccountOrder(orderKeys)
    }

    /**
     * Apply saved account order to the list of account groups.
     */
    private fun applyAccountOrder(accountGroups: List<AccountGroup>): List<AccountGroup> {
        val savedOrder = userPreferences.getAccountOrder()
        if (savedOrder.isEmpty()) {
            return accountGroups
        }

        // Check if we have separate groups (when combine accounts is disabled)
        val hasSeparateGroups = accountGroups.any { group ->
            accountGroups.count { it.issuer == group.issuer && it.accountName == group.accountName } > 1
        }

        return if (hasSeparateGroups) {
            applySeparateGroupOrdering(accountGroups, savedOrder)
        } else {
            applyCombinedGroupOrdering(accountGroups, savedOrder)
        }
    }

    /**
     * Apply ordering for separate account groups (when combine accounts is disabled).
     * Groups OATH and Push cards from the same account together and maintains saved order.
     */
    private fun applySeparateGroupOrdering(
        accountGroups: List<AccountGroup>,
        savedOrder: List<String>
    ): List<AccountGroup> {
        // Group the separate cards by account (issuer + accountName)
        val groupsByAccount = accountGroups.groupBy { "${it.issuer}-${it.accountName}" }

        val orderedList = mutableListOf<AccountGroup>()
        val processedAccounts = mutableSetOf<String>()

        // Process accounts in saved order
        savedOrder.forEach { accountKey ->
            groupsByAccount[accountKey]?.let { accountCards ->
                // Sort cards within account: OATH first, then Push
                val sortedCards = accountCards.sortedWith { a, b ->
                    when {
                        a.oathCredentials.isNotEmpty() && b.pushCredentials.isNotEmpty() -> -1 // OATH first
                        a.pushCredentials.isNotEmpty() && b.oathCredentials.isNotEmpty() -> 1   // Push second
                        else -> 0 // Same type, maintain existing order
                    }
                }
                orderedList.addAll(sortedCards)
                processedAccounts.add(accountKey)
            }
        }

        // Add any new accounts not in saved order
        groupsByAccount.entries.forEach { (accountKey, accountCards) ->
            if (!processedAccounts.contains(accountKey)) {
                val sortedCards = accountCards.sortedWith { a, b ->
                    when {
                        a.oathCredentials.isNotEmpty() && b.pushCredentials.isNotEmpty() -> -1
                        a.pushCredentials.isNotEmpty() && b.oathCredentials.isNotEmpty() -> 1
                        else -> 0
                    }
                }
                orderedList.addAll(sortedCards)
            }
        }

        return orderedList
    }

    /**
     * Apply ordering for combined account groups (when combine accounts is enabled).
     */
    private fun applyCombinedGroupOrdering(
        accountGroups: List<AccountGroup>,
        savedOrder: List<String>
    ): List<AccountGroup> {
        // Create a map for quick lookup (only for combined accounts)
        val accountMap = accountGroups.associateBy { "${it.issuer}-${it.accountName}" }
        val orderedList = mutableListOf<AccountGroup>()
        val addedKeys = mutableSetOf<String>()

        // Add accounts in saved order
        savedOrder.forEach { key ->
            accountMap[key]?.let { accountGroup ->
                orderedList.add(accountGroup)
                addedKeys.add(key)
            }
        }

        // Add any new accounts that weren't in the saved order
        accountGroups.forEach { accountGroup ->
            val key = "${accountGroup.issuer}-${accountGroup.accountName}"
            if (!addedKeys.contains(key)) {
                orderedList.add(accountGroup)
            }
        }

        return orderedList
    }
}