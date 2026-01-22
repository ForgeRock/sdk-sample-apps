//
//  UserPreferences.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine

/// UserDefaults wrapper for app preferences with Combine support.
@MainActor
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let themeMode = "themeMode"
        static let combineAccounts = "combineAccounts"
        static let copyOtp = "copyOtp"
        static let tapToReveal = "tapToReveal"
        static let diagnosticLogging = "diagnosticLogging"
        static let accountOrder = "accountOrder"
        static let isFirstLaunch = "isFirstLaunch"
    }

    // MARK: - Published Properties
    @Published var themeMode: ThemeMode {
        didSet {
            defaults.set(themeMode.rawValue, forKey: Keys.themeMode)
        }
    }

    @Published var combineAccounts: Bool {
        didSet {
            defaults.set(combineAccounts, forKey: Keys.combineAccounts)
        }
    }

    @Published var copyOtp: Bool {
        didSet {
            defaults.set(copyOtp, forKey: Keys.copyOtp)
        }
    }

    @Published var tapToReveal: Bool {
        didSet {
            defaults.set(tapToReveal, forKey: Keys.tapToReveal)
        }
    }

    @Published var diagnosticLogging: Bool {
        didSet {
            defaults.set(diagnosticLogging, forKey: Keys.diagnosticLogging)
        }
    }

    @Published var isFirstLaunch: Bool {
        didSet {
            defaults.set(isFirstLaunch, forKey: Keys.isFirstLaunch)
        }
    }

    // MARK: - Initialization
    private init() {
        // Load theme mode
        if let themeModeString = defaults.string(forKey: Keys.themeMode),
           let loadedThemeMode = ThemeMode(rawValue: themeModeString) {
            self.themeMode = loadedThemeMode
        } else {
            self.themeMode = .system
        }

        // Load other preferences
        self.combineAccounts = defaults.object(forKey: Keys.combineAccounts) as? Bool ?? true
        self.copyOtp = defaults.object(forKey: Keys.copyOtp) as? Bool ?? false
        self.tapToReveal = defaults.object(forKey: Keys.tapToReveal) as? Bool ?? false
        self.diagnosticLogging = defaults.object(forKey: Keys.diagnosticLogging) as? Bool ?? false
        self.isFirstLaunch = defaults.object(forKey: Keys.isFirstLaunch) as? Bool ?? true
    }

    // MARK: - Account Ordering
    /// Get the saved order of account IDs
    func getAccountOrder() -> [String] {
        defaults.stringArray(forKey: Keys.accountOrder) ?? []
    }

    /// Save the order of account IDs
    func setAccountOrder(_ order: [String]) {
        defaults.set(order, forKey: Keys.accountOrder)
    }

    // MARK: - Reset
    /// Reset all preferences to default values
    func resetToDefaults() {
        themeMode = .system
        combineAccounts = true
        copyOtp = false
        tapToReveal = false
        diagnosticLogging = false
        isFirstLaunch = false
        defaults.removeObject(forKey: Keys.accountOrder)
    }
}
