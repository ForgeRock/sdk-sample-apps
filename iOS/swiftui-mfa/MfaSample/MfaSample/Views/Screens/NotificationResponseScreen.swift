//
//  NotificationResponseScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingPush

/// Screen for responding to push notifications (DEFAULT, BIOMETRIC, CHALLENGE).
struct NotificationResponseScreen: View {
    @StateObject private var viewModel: NotificationResponseViewModel
    @Environment(\.dismiss) private var dismiss

    init(notificationItem: PushNotificationItem) {
        _viewModel = StateObject(wrappedValue: NotificationResponseViewModel(notificationItem: notificationItem))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Notification Info Header
                notificationHeader

                Divider()

                // Content based on push type
                switch viewModel.notificationItem.notification.pushType {
                case .challenge:
                    challengeView
                case .biometric:
                    biometricView
                case .default:
                    defaultView
                @unknown default:
                    defaultView
                }
            }
            .padding()
        }
        .navigationTitle("Authentication Request")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
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
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    // MARK: - Notification Header
    private var notificationHeader: some View {
        VStack(spacing: 12) {
            // Service Info
            if let issuer = viewModel.notificationItem.credential?.issuer {
                Text(issuer)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            if let accountName = viewModel.notificationItem.credential?.accountName {
                Text(accountName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Message
            if let message = viewModel.notificationItem.notification.messageText {
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            // Context Info (if available)
            if let contextInfo = viewModel.notificationItem.notification.contextInfo, !contextInfo.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Context Information")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(contextInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Push Type Views
    private var defaultView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 8) {
                Text("Approve or Deny")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Was this authentication request made by you?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            actionButtons
        }
        .padding(.vertical, 32)
    }

    private var biometricView: some View {
        BiometricPromptView(
            biometricType: viewModel.biometricType,
            onAuthenticate: {
                Task {
                    await viewModel.approve()
                }
            },
            onCancel: {
                Task {
                    await viewModel.deny()
                }
            }
        )
    }

    private var challengeView: some View {
        let challengeNumbers = viewModel.notificationItem.notification.getNumbersChallenge()
        
        return VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                
                Text("Select the Matching Number")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("Which number matches the one shown on your other device?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            if !challengeNumbers.isEmpty {
                // Challenge number buttons
                HStack(spacing: 20) {
                    ForEach(challengeNumbers, id: \.self) { number in
                        challengeNumberButton(number: number) {
                            Task {
                                await viewModel.approve(challengeResponse: String(number))
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Deny/Cancel button
                Button(action: {
                    Task {
                        await viewModel.deny()
                    }
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.isProcessing)
                .padding(.horizontal, 32)
            } else {
                // Error state - no challenge numbers available
                VStack(spacing: 16) {
                    Text("Invalid Challenge")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text("No challenge numbers available. Please contact support.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 32)
    }

    // MARK: - Challenge Number Button
    private func challengeNumberButton(number: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(String(number))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 80, height: 80)
                .background(Color.clear)
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                )
        }
        .disabled(viewModel.isProcessing)
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await viewModel.approve()
                }
            }) {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Approve")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isProcessing)

            Button(action: {
                Task {
                    await viewModel.deny()
                }
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Deny")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isProcessing)
        }
        .padding(.horizontal, 32)
    }

}

#Preview {
    NavigationView {
        NotificationResponseScreen(
            notificationItem: PushNotificationItem(
                notification: PushNotification(
                    id: "1",
                    credentialId: "cred-123",
                    ttl: 300,
                    messageId: "msg-123",
                    messageText: "Login attempt from new device",
                    pushType: .default
                ),
                credential: nil,
                status: .pending
            )
        )
    }
}
