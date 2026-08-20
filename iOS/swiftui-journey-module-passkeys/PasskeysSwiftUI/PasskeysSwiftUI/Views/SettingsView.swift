//
//  SettingsView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import PingOrchestrate

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var registrationViewModel = RegistrationViewModel()
    @State private var biometricsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKey.biometricsEnabled)

    var body: some View {
        NavigationStack {
            ZStack {
                settingsForm
                if registrationViewModel.isLoading {
                    LoadingOverlay("Registering passkey…")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.pingRed)
                }
            }
            .onChange(of: registrationViewModel.isRegistered) { _, registered in
                if registered { dismiss() }
            }
            .onChange(of: registrationViewModel.isFailure) { _, isFailure in
                if isFailure { biometricsEnabled = false }
            }
        }
    }

    // MARK: - Settings Form

    private var settingsForm: some View {
        Form {
            biometricsSection
            registrationSection
            errorSection
        }
        .tint(.pingRed)
    }

    private var biometricsSection: some View {
        Section {
            Toggle("Biometric / Passkey Login", isOn: $biometricsEnabled)
                .onChange(of: biometricsEnabled) { _, isEnabled in
                    if isEnabled {
                        Task { await registrationViewModel.startRegistration() }
                    } else {
                        UserDefaults.standard.set(false, forKey: UserDefaultsKey.biometricsEnabled)
                    }
                }
        } header: {
            Text("Authentication")
        } footer: {
            Text(biometricsEnabled
                 ? "Passkey login is enabled. You will be prompted with Face ID or Touch ID on the next sign-in."
                 : "Enable to register a passkey for biometric login.")
        }
    }

    @ViewBuilder
    private var registrationSection: some View {
        if let continueNode = registrationViewModel.node as? ContinueNode {
            Section("Passkey Registration") {
                ContinueNodeView(node: continueNode, onNext: {
                    Task { await registrationViewModel.next(continueNode: continueNode) }
                })
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private var errorSection: some View {
        if let failureNode = registrationViewModel.node as? FailureNode {
            Section {
                Label(failureNode.cause.localizedDescription, systemImage: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        } else if let errorNode = registrationViewModel.node as? ErrorNode {
            Section {
                Label(
                    errorNode.message.isEmpty ? "An error occurred during registration." : errorNode.message,
                    systemImage: "xmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundColor(.red)
            }
        }
    }
}
