//
//  LoginScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import PingOrchestrate
import PingJourneyPlugin

/// Screen for Journey-based authentication with dynamic callback rendering.
struct LoginScreen: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.currentNode == nil {
                // Initial loading
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                        .foregroundColor(.secondary)
                }
            } else if let node = viewModel.currentNode,
                      let continueNode = node as? ContinueNode {
                // Node with callbacks
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("Sign In")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Please enter your credentials to continue")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 32)

                        // Callbacks
                        VStack(spacing: 16) {
                            ForEach(Array(continueNode.callbacks.enumerated()), id: \.offset) { index, callback in
                                if let abstractCallback = callback as? AbstractCallback {
                                    CallbackView(
                                        callback: abstractCallback,
                                        index: index,
                                        viewModel: viewModel
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Submit Button
                        Button(action: {
                            Task {
                                await viewModel.submitNode()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .padding(.bottom, 32)
                }
            } else {
                // No node (shouldn't happen)
                Text("No authentication flow available")
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    viewModel.cleanup()
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.startLogin()
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

// MARK: - Callback View

/// Renders a specific callback based on its type.
struct CallbackView: View {
    let callback: AbstractCallback
    let index: Int
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        let key = viewModel.getCallbackKey(for: callback, at: index)

        Group {
            if let nameCallback = callback as? NameCallback {
                VStack(alignment: .leading, spacing: 4) {
                    if !nameCallback.prompt.isEmpty {
                        Text(nameCallback.prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    TextField("Username", text: binding(for: key))
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .textFieldStyle(.roundedBorder)
                }
            } else if let passwordCallback = callback as? PasswordCallback {
                VStack(alignment: .leading, spacing: 4) {
                    if !passwordCallback.prompt.isEmpty {
                        Text(passwordCallback.prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    SecureField("Password", text: binding(for: key))
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                }
            } else if let textCallback = callback as? TextInputCallback {
                VStack(alignment: .leading, spacing: 4) {
                    if !textCallback.prompt.isEmpty {
                        Text(textCallback.prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    TextField(textCallback.prompt, text: binding(for: key))
                        .textFieldStyle(.roundedBorder)
                }
            } else if let choiceCallback = callback as? ChoiceCallback {
                VStack(alignment: .leading, spacing: 4) {
                    if !choiceCallback.prompt.isEmpty {
                        Text(choiceCallback.prompt)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Picker("", selection: binding(for: key)) {
                        ForEach(0..<choiceCallback.choices.count, id: \.self) { index in
                            Text(choiceCallback.choices[index]).tag(String(index))
                        }
                    }
                    .pickerStyle(.menu)
                }
            } else if let textOutputCallback = callback as? TextOutputCallback {
                // Display-only text
                VStack(alignment: .leading, spacing: 4) {
                    Text(textOutputCallback.message)
                        .font(.body)
                        .foregroundColor(textOutputCallback.messageType == .error ? .red : .primary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            } else if callback is HiddenValueCallback {
                // Hidden callbacks don't render UI
                EmptyView()
            } else {
                // Unsupported callback type
                Text("Unsupported callback: \(String(describing: type(of: callback)))")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { viewModel.callbackValues[key] ?? "" },
            set: { viewModel.callbackValues[key] = $0 }
        )
    }
}

#Preview {
    NavigationView {
        LoginScreen()
    }
}
