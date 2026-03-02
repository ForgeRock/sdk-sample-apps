//
//  AccountsViewModel.swift
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

/// ViewModel for the main Accounts screen.
/// Coordinates between managers and handles TOTP auto-refresh logic.
@MainActor
class AccountsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let oathManager = OathManager.shared
    private let pushManager = PushManager.shared
    private let accountGroupingManager = AccountGroupingManager.shared
    private let userPreferences = UserPreferences.shared
    private let appConfiguration = AppConfiguration.shared

    // MARK: - Published State
    @Published var accountGroups: [AccountGroup] = []
    @Published var generatedCodes: [String: OathCodeInfo] = [:]
    @Published var pushNotifications: [PushNotification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRefreshing: Bool = false

    // MARK: - Computed Preferences
    var copyOtp: Bool { userPreferences.copyOtp }
    var tapToReveal: Bool { userPreferences.tapToReveal }

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    // MARK: - Initialization
    init() {
        setupObservers()
    }

    deinit {
        refreshTask?.cancel()
    }

    // MARK: - Setup
    /// Sets up observers for manager state changes.
    private func setupObservers() {
        // Observe OATH credentials changes
        oathManager.$oathCredentials
            .combineLatest(pushManager.$pushCredentials, userPreferences.$combineAccounts)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] oathCreds, pushCreds, shouldCombine in
                self?.updateAccountGroups(oathCredentials: oathCreds, pushCredentials: pushCreds, shouldCombine: shouldCombine)
            }
            .store(in: &cancellables)

        // Mirror generated codes so AccountGroupCard doesn't need to observe OathManager directly
        oathManager.$generatedCodes
            .receive(on: DispatchQueue.main)
            .assign(to: &$generatedCodes)

        // Mirror push notifications so views can look up last login attempt
        pushManager.$pushNotifications
            .receive(on: DispatchQueue.main)
            .assign(to: &$pushNotifications)

        // Observe loading states
        oathManager.$isLoadingCredentials
            .combineLatest(pushManager.$isLoadingCredentials)
            .receive(on: DispatchQueue.main)
            .map { $0 || $1 }
            .assign(to: &$isLoading)

        // Restart TOTP refresh timer when credentials change.
        oathManager.$oathCredentials
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.stopTOTPRefreshTimer()
                self?.startTOTPRefreshTimer()
            }
            .store(in: &cancellables)
    }

    // MARK: - Account Groups
    /// Updates account groups based on current credentials and settings.
    private func updateAccountGroups(oathCredentials: [OathCredential], pushCredentials: [PushCredential], shouldCombine: Bool) {
        let grouped = accountGroupingManager.groupCredentialsByAccount(
            oathCredentials: oathCredentials,
            pushCredentials: pushCredentials,
            shouldCombine: shouldCombine
        )
        self.accountGroups = accountGroupingManager.applyOrdering(to: grouped)
    }

    // MARK: - Data Loading
    /// Loads all credentials and notifications.
    func loadData() async {
        isLoading = true
        errorMessage = nil

        // Ensure SDK is initialized before loading data
        await appConfiguration.initialize()

        do {
            async let oathCreds = oathManager.loadCredentials()
            async let pushCreds = pushManager.loadCredentials()
            async let notifications = pushManager.loadAllPushNotifications()

            _ = try await (oathCreds, pushCreds, notifications)
            
            // Generate initial codes for all credentials (HOTP always, TOTP when missing)
            await generateInitialCodes()
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    /// Generates initial codes for credentials on app launch.
    private func generateInitialCodes() async {
        let credentials = oathManager.oathCredentials
        guard !credentials.isEmpty else { return }
        await withTaskGroup(of: Void.self) { group in
            for credential in credentials {
                switch credential.oathType {
                case .hotp:
                    // Always generate HOTP codes when credentials load
                    group.addTask { [oathManager] in
                        _ = try? await oathManager.generateCode(for: credential.id)
                    }
                case .totp:
                    // Generate TOTP codes if not locked and no code exists yet
                    if !credential.isLocked && oathManager.generatedCodes[credential.id] == nil {
                        group.addTask { [oathManager] in
                            _ = try? await oathManager.generateCode(for: credential.id)
                        }
                    }
                }
            }
        }
    }

    /// Refreshes all data (for pull-to-refresh).
    func refresh() async {
        isRefreshing = true
        await loadData()
        isRefreshing = false
    }

    // MARK: - TOTP Auto-Refresh
    /// Starts the TOTP auto-refresh loop using an intelligent delay approach
    /// Sleep until the next TOTP code expires rather than polling every second.
    /// This avoids unnecessary main-thread work.
    private func startTOTPRefreshTimer() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self else { break }

                // Read credentials directly from oathManager
                let totpCredentials = self.oathManager.oathCredentials.filter { $0.oathType == .totp }

                // If no TOTP credentials, sleep for a longer default and re-check
                guard !totpCredentials.isEmpty else {
                    try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                    continue
                }

                let currentTimeSeconds = Int(Date().timeIntervalSince1970)

                // Calculate minimum time remaining until any TOTP code expires
                let minRemainingSeconds = totpCredentials.compactMap { credential -> Int? in
                    let periodSeconds = credential.period
                    guard periodSeconds > 0 else { return nil }
                    let elapsedInPeriod = currentTimeSeconds % periodSeconds
                    return periodSeconds - elapsedInPeriod
                }.min()

                // Sleep until the soonest code expires (minimum 1 second to avoid tight loops)
                let delaySeconds = max(1, minRemainingSeconds ?? 30)
                try? await Task.sleep(nanoseconds: UInt64(delaySeconds) * 1_000_000_000)
                guard !Task.isCancelled else { break }

                // After waking, regenerate codes for all TOTP credentials.
                // Re-read from oathManager in case credentials changed during sleep.
                let credentialsToRefresh = self.oathManager.oathCredentials.filter { $0.oathType == .totp }
                for credential in credentialsToRefresh {
                    guard !Task.isCancelled else { return }
                    _ = try? await self.oathManager.generateCode(for: credential.id)
                }
            }
        }
    }

    /// Pauses the TOTP auto-refresh loop (e.g., while a sheet is presented).
    /// This avoids main-thread work during animations and keyboard transitions.
    func pauseTOTPRefresh() {
        stopTOTPRefreshTimer()
    }

    /// Resumes the TOTP auto-refresh loop after a pause.
    func resumeTOTPRefresh() {
        guard refreshTask == nil else { return }
        startTOTPRefreshTimer()
    }

    /// Stops the TOTP auto-refresh loop.
    private func stopTOTPRefreshTimer() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    // MARK: - Code Generation
    /// Generates a code for a specific credential (for HOTP or manual refresh).
    func generateCode(for credentialId: String) async {
        do {
            _ = try await oathManager.generateCode(for: credentialId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Account Management
    /// Deletes a credential.
    func deleteCredential(oathCredentialId: String?, pushCredentialId: String?) async {
        do {
            if let oathId = oathCredentialId {
                _ = try await oathManager.removeCredential(oathId)
            }
            if let pushId = pushCredentialId {
                _ = try await pushManager.removeCredential(pushId)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Updates the order of account groups.
    func updateAccountOrder(_ groups: [AccountGroup]) {
        self.accountGroups = groups
        accountGroupingManager.saveOrdering(for: groups)
    }

    // MARK: - Helper Methods
    /// Gets the generated code info for a credential.
    func getCodeInfo(for credentialId: String) -> OathCodeInfo? {
        return oathManager.generatedCodes[credentialId]
    }

    /// Returns the date of the most recent push notification for a given push credential.
    func lastLoginAttempt(for credentialId: String) -> Date? {
        pushNotifications
            .filter { $0.credentialId == credentialId }
            .map { $0.createdAt }
            .max()
    }

    /// Clears the current error message.
    func clearError() {
        errorMessage = nil
    }
}
