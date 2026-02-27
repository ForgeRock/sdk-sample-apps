//
//  AccountDetailScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOath
import PingPush

/// Screen for viewing and editing account details.
struct AccountDetailScreen: View {
    @StateObject private var viewModel: AccountDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(accountGroup: AccountGroup) {
        _viewModel = StateObject(wrappedValue: AccountDetailViewModel(accountGroup: accountGroup))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header Section
                accountInfoSection

                // Credentials Section
                credentialsSection

                // Actions Section
                actionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Account Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { viewModel.showEditDialog = true }) {
                    Label("Edit", systemImage: "pencil")
                }
                .disabled(viewModel.accountGroup.isLocked)
            }
        }
        .sheet(isPresented: $viewModel.showEditDialog) {
            EditAccountDialog(
                account: viewModel.accountGroup,
                onDismiss: { viewModel.showEditDialog = false },
                onConfirm: { newIssuer, newAccountName in
                    viewModel.showEditDialog = false
                    Task { await viewModel.updateDisplayNames(issuer: newIssuer, accountName: newAccountName) }
                }
            )
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
        .confirmationDialog("Choose What to Delete", isPresented: $viewModel.showDeleteTypeSelection) {
            if viewModel.hasOathCredentials {
                Button("Delete OATH Only", role: .destructive) {
                    viewModel.pendingDeleteType = .oathOnly
                    viewModel.showDeleteConfirmation = true
                }
            }
            if viewModel.hasPushCredentials {
                Button("Delete Push Only", role: .destructive) {
                    viewModel.pendingDeleteType = .pushOnly
                    viewModel.showDeleteConfirmation = true
                }
            }
            Button("Delete All", role: .destructive) {
                viewModel.pendingDeleteType = .both
                viewModel.showDeleteConfirmation = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This account has both OATH and Push credentials. What would you like to delete?")
        }
        .confirmationDialog("Delete Account", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    // MARK: - Account Info Section
    private var accountInfoSection: some View {
        VStack(spacing: 12) {
            AccountAvatar(
                issuer: viewModel.accountGroup.displayIssuer.isEmpty ? viewModel.accountGroup.issuer : viewModel.accountGroup.displayIssuer,
                accountName: viewModel.accountGroup.displayAccountName.isEmpty ? viewModel.accountGroup.accountName : viewModel.accountGroup.displayAccountName,
                imageURL: viewModel.accountGroup.imageURL,
                size: 80
            )

            Text(viewModel.accountGroup.displayIssuer.isEmpty ? viewModel.accountGroup.issuer : viewModel.accountGroup.displayIssuer)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text(viewModel.accountGroup.displayAccountName.isEmpty ? viewModel.accountGroup.accountName : viewModel.accountGroup.displayAccountName)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if viewModel.accountGroup.isLocked {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14))
                    Text("Locked")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.orange)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Credentials Section
    private var credentialsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // OATH Credentials
            if viewModel.hasOathCredentials {
                VStack(alignment: .leading, spacing: 8) {
                    Label("OATH (Time-based Codes)", systemImage: "timer")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.accountGroup.oathCredentials) { credential in
                        OathCredentialRow(credential: credential)
                    }
                }
            }

            // Push Credentials
            if viewModel.hasPushCredentials {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Push Authentication", systemImage: "bell.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(viewModel.accountGroup.pushCredentials) { credential in
                        PushCredentialRow(credential: credential)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Delete Button
            Button(action: {
                viewModel.prepareDelete()
            }) {
                HStack {
                    if viewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "trash.fill")
                        Text("Delete Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themeButtonBackground)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isProcessing)
        }
    }
}

// MARK: - Helper Views
private struct OathCredentialRow: View {
    let credential: OathCredential

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CredentialDetailRow(label: "Type", value: credential.oathType.rawValue.uppercased())
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "ID", value: credential.id)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Issuer", value: credential.issuer)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Account Name", value: credential.accountName)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Display Issuer", value: credential.displayIssuer)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Display Account", value: credential.displayAccountName)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Algorithm", value: credential.oathAlgorithm.rawValue.uppercased())
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Digits", value: "\(credential.digits)")

            if credential.oathType == .totp {
                Divider().padding(.leading, 100)
                CredentialDetailRow(label: "Period", value: "\(credential.period)s")
            }

            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Created", value: formatDate(credential.createdAt))

            if credential.isLocked {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("Locked")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct PushCredentialRow: View {
    let credential: PushCredential

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CredentialDetailRow(label: "ID", value: credential.id)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Resource ID", value: credential.resourceId)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Issuer", value: credential.issuer)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Account Name", value: credential.accountName)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Display Issuer", value: credential.displayIssuer)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Display Account", value: credential.displayAccountName)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Platform", value: credential.platform.rawValue)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Server Endpoint", value: credential.serverEndpoint)
            Divider().padding(.leading, 100)
            CredentialDetailRow(label: "Created", value: formatDate(credential.createdAt))

            if let userId = credential.userId {
                Divider().padding(.leading, 100)
                CredentialDetailRow(label: "User ID", value: userId)
            }

            if credential.isLocked {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("Locked")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.orange)
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct CredentialDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    NavigationView {
        AccountDetailScreen(
            accountGroup: AccountGroup(
                issuer: "example.com",
                accountName: "user@example.com",
                displayIssuer: "Example Service",
                displayAccountName: "user@example.com",
                oathCredentials: [],
                pushCredentials: []
            )
        )
    }
}
