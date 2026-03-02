//
//  SettingsScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Screen for managing app settings and preferences.
struct SettingsScreen: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        List {
            // Appearance Section
            Section {
                Picker("Theme", selection: $viewModel.themeMode) {
                    ForEach(ThemeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            } header: {
                Text("Appearance")
            }

            // Account Management Section
            Section {
                Toggle("Combine Accounts", isOn: $viewModel.combineAccounts)
                Toggle("Copy OTP tokens when tapped", isOn: $viewModel.copyOtp)
                Toggle("Tap to reveal", isOn: $viewModel.tapToReveal)
            } header: {
                Text("Account Management")
            } footer: {
                Text("Combine accounts groups credentials with the same issuer and account name. Copy OTP tokens to the clipboard when tapped. When tap to reveal is on, OTP codes are hidden by default — tap the code to reveal it.")
            }

            // Diagnostic Logs Section
            Section {
                Toggle("Enable diagnostic logging", isOn: $viewModel.diagnosticLogging)

                if viewModel.diagnosticLogging {
                    NavigationLink(destination: DiagnosticLogsScreen()) {
                        Label("View diagnostic logs", systemImage: "doc.text.fill")
                    }
                }
            } header: {
                Text("Diagnostic Logs")
            } footer: {
                Text("Automatically collect errors from the app. Enable to view and export captured diagnostic logs.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationView {
        SettingsScreen()
    }
}
