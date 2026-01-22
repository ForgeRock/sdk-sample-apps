//
//  SettingsViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine

/// ViewModel for managing app settings and preferences.
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let preferences = UserPreferences.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Published State
    @Published var themeMode: ThemeMode
    @Published var combineAccounts: Bool
    @Published var copyOtp: Bool
    @Published var tapToReveal: Bool
    @Published var diagnosticLogging: Bool
    @Published var showResetConfirmation = false

    // MARK: - Computed Properties
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    // MARK: - Initialization
    init() {
        // Initialize from preferences
        self.themeMode = preferences.themeMode
        self.combineAccounts = preferences.combineAccounts
        self.copyOtp = preferences.copyOtp
        self.tapToReveal = preferences.tapToReveal
        self.diagnosticLogging = preferences.diagnosticLogging

        // Sync changes back to preferences
        $themeMode
            .sink { [weak self] newValue in
                self?.preferences.themeMode = newValue
            }
            .store(in: &cancellables)

        $combineAccounts
            .sink { [weak self] newValue in
                self?.preferences.combineAccounts = newValue
            }
            .store(in: &cancellables)

        $copyOtp
            .sink { [weak self] newValue in
                self?.preferences.copyOtp = newValue
            }
            .store(in: &cancellables)

        $tapToReveal
            .sink { [weak self] newValue in
                self?.preferences.tapToReveal = newValue
            }
            .store(in: &cancellables)

        $diagnosticLogging
            .sink { [weak self] newValue in
                self?.preferences.diagnosticLogging = newValue
            }
            .store(in: &cancellables)
    }

}
