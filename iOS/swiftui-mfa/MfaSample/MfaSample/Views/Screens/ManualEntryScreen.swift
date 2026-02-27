//
//  ManualEntryScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Screen for manually entering OATH credential details.
struct ManualEntryScreen: View {
    @StateObject private var viewModel = ManualEntryViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum Field {
        case issuer, accountName, secretKey
    }

    var body: some View {
        Form {
            // Basic Information
            Section {
                TextField("Account Name", text: $viewModel.accountName)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .accountName)

                TextField("Issuer (Optional)", text: $viewModel.issuer)
                    .focused($focusedField, equals: .issuer)

            } header: {
                Text("Account Information")
            } footer: {
                Text("Account name is required. Issuer helps identify the service.")
            }

            // Secret Key
            Section {
                TextField("Secret Key", text: $viewModel.secretKey)
                    .textContentType(.oneTimeCode)
                    .autocapitalization(.allCharacters)
                    .focused($focusedField, equals: .secretKey)
                    .onChange(of: viewModel.secretKey) { _ in
                        viewModel.formatSecretKey()
                    }

            } header: {
                Text("Secret Key")
            } footer: {
                Text("Base32-encoded secret key (A-Z, 2-7). Spaces will be removed automatically.")
            }

            // Type and Algorithm
            Section {
                Picker("Type", selection: $viewModel.oathType) {
                    ForEach(ManualEntryViewModel.OathType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                Picker("Algorithm", selection: $viewModel.algorithm) {
                    ForEach(ManualEntryViewModel.OathAlgorithm.allCases) { algorithm in
                        Text(algorithm.rawValue).tag(algorithm)
                    }
                }

                Stepper("Digits: \(viewModel.digits)", value: $viewModel.digits, in: 6...8)

            } header: {
                Text("Configuration")
            }

            // Type-specific Parameters
            Section {
                if viewModel.oathType == .totp {
                    Stepper("Period: \(viewModel.period)s", value: $viewModel.period, in: 15...60, step: 15)
                } else {
                    Stepper("Counter: \(viewModel.counter)", value: $viewModel.counter, in: 0...999)
                }
            } header: {
                Text(viewModel.oathType == .totp ? "TOTP Settings" : "HOTP Settings")
            } footer: {
                if viewModel.oathType == .totp {
                    Text("Period is the time window in seconds for code generation (typically 30).")
                } else {
                    Text("Counter is incremented with each code generation (typically starts at 0).")
                }
            }

            // Submit Button
            Section {
                Button(action: {
                    focusedField = nil  // Dismiss keyboard
                    Task {
                        await viewModel.registerCredential()
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Add Account")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(!viewModel.isFormValid || viewModel.isProcessing)
            }
        }
        .navigationTitle("Manual Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.clearError() } }
        )) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
}

#Preview {
    NavigationView {
        ManualEntryScreen()
    }
}
