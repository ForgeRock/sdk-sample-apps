//
//  AccountsScreen.swift
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

/// Main screen displaying all account groups with MFA credentials.
struct AccountsScreen: View {
    @EnvironmentObject private var viewModel: AccountsViewModel
    @EnvironmentObject var appConfiguration: AppConfiguration

    // Navigation callbacks
    let onScanQrCode: () -> Void
    let onManualEntry: () -> Void
    let onLogin: () -> Void
    let onAccountTap: (AccountGroup) -> Void
    let onPushNotifications: () -> Void
    let onSettings: () -> Void
    let onEditAccounts: ([AccountGroup]) -> Void
    let onAbout: () -> Void

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.accountGroups.isEmpty {
                // Initial loading state
                ProgressView("Loading accounts...")
            } else if !viewModel.isLoading && viewModel.accountGroups.isEmpty {
                // Empty state
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Accounts",
                    message: "Add your first account to get started with multi-factor authentication."
                )
            } else {
                // Account list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.accountGroups) { group in
                            AccountGroupCard(
                                accountGroup: group,
                                codeInfo: viewModel.generatedCodes[group.oathCredentials.first?.id ?? ""],
                                lastNotificationDate: group.pushCredentials.first.flatMap { viewModel.lastLoginAttempt(for: $0.id) },
                                copyOtp: viewModel.copyOtp,
                                tapToReveal: viewModel.tapToReveal,
                                onGenerateCode: {
                                    if let credentialId = group.oathCredentials.first?.id {
                                        Task {
                                            await viewModel.generateCode(for: credentialId)
                                        }
                                    }
                                },
                                onTap: {
                                    onAccountTap(group)
                                }
                            )
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteCredential(
                                            oathCredentialId: group.oathCredentials.first?.id,
                                            pushCredentialId: group.pushCredentials.first?.id
                                        )
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottomTrailing) {
            // Floating action button — hidden during initial loading
            if !(viewModel.isLoading && viewModel.accountGroups.isEmpty) {
                Menu {
                    Button(action: onScanQrCode) {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                    }
                    Button(action: onManualEntry) {
                        Label("Manual Entry", systemImage: "keyboard")
                    }
                    Button(action: onLogin) {
                        Label("Login (Journey)", systemImage: "person.crop.circle")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.themeButtonBackground)
                        .clipShape(Circle())
                        .shadow(radius: 4, x: 0, y: 2)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image("PingLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text("Authenticator")
                        .font(.headline)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: onPushNotifications) {
                        Label("Notifications", systemImage: "bell")
                    }
                    Button(action: {
                        onEditAccounts(viewModel.accountGroups)
                    }) {
                        Label("Edit Accounts", systemImage: "pencil")
                    }
                    .disabled(viewModel.accountGroups.isEmpty)
                    Button(action: onSettings) {
                        Label("Settings", systemImage: "gear")
                    }
                    Button(action: onAbout) {
                        Label("About", systemImage: "info.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
        .task {
            // loadData() already calls appConfiguration.initialize() internally
            await viewModel.loadData()
        }
    }
}

#Preview {
    AccountsScreen(
        onScanQrCode: {},
        onManualEntry: {},
        onLogin: {},
        onAccountTap: { _ in },
        onPushNotifications: {},
        onSettings: {},
        onEditAccounts: { _ in },
        onAbout: {}
    )
}
