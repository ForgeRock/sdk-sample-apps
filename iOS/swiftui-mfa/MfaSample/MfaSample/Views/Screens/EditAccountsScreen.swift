//
//  EditAccountsScreen.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// Screen for reordering, editing display names, and deleting accounts.
struct EditAccountsScreen: View {
    @StateObject private var viewModel: EditAccountsViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Deletion state
    @State private var accountToDelete: AccountGroup?
    @State private var deleteType: DeleteType?

    // MARK: - Edit state
    @State private var accountToEdit: AccountGroup?

    init(accountGroups: [AccountGroup], onSaveOrder: (([AccountGroup]) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: EditAccountsViewModel(accountGroups: accountGroups, onSaveOrder: onSaveOrder))
    }

    var body: some View {
        accountList
            .navigationTitle("Edit Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let msg = viewModel.errorMessage { Text(msg) }
            }
            .sheet(item: $accountToEdit) { account in
                EditAccountDialog(
                    account: account,
                    onDismiss: { accountToEdit = nil },
                    onConfirm: { newIssuer, newAccountName in
                        accountToEdit = nil
                        Task { await viewModel.updateAccountDisplayInfo(account, displayIssuer: newIssuer, displayAccountName: newAccountName) }
                    }
                )
            }
    }

    // MARK: - Sub-views
    private var accountList: some View {
        List {
            Section {
                ForEach(viewModel.accountGroups) { group in
                    AccountRowView(
                        group: group,
                        onEdit: { accountToEdit = group },
                        onDelete: { beginDelete(group) }
                    )
                    .confirmationDialog(
                        "Choose What to Delete",
                        isPresented: Binding(
                            get: { accountToDelete?.id == group.id && deleteType == nil },
                            set: { if !$0 { accountToDelete = nil; deleteType = nil } }
                        ),
                        titleVisibility: .visible
                    ) {
                        if !group.oathCredentials.isEmpty {
                            Button("Delete OATH Only", role: .destructive) { deleteType = .oathOnly }
                        }
                        if !group.pushCredentials.isEmpty {
                            Button("Delete Push Only", role: .destructive) { deleteType = .pushOnly }
                        }
                        Button("Delete All", role: .destructive) { deleteType = .both }
                        Button("Cancel", role: .cancel) { accountToDelete = nil }
                    } message: {
                        Text("'\(group.displayIssuer) – \(group.displayAccountName)' has multiple authentication methods.")
                    }
                    .confirmationDialog(
                        "Confirm Deletion",
                        isPresented: Binding(
                            get: { accountToDelete?.id == group.id && deleteType != nil },
                            set: { if !$0 { accountToDelete = nil; deleteType = nil } }
                        ),
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) { performDelete() }
                        Button("Cancel", role: .cancel) { accountToDelete = nil; deleteType = nil }
                    } message: {
                        if let type = deleteType {
                            let description: String = {
                                switch type {
                                case .oathOnly: return "OATH credential(s)"
                                case .pushOnly: return "Push credential(s)"
                                case .both:     return "all credentials"
                                }
                            }()
                            Text("Delete \(description) for '\(group.displayIssuer) – \(group.displayAccountName)'?")
                        }
                    }
                }
                .onMove(perform: viewModel.moveAccount)
            } header: {
                Text("Drag to reorder")
            } footer: {
                if viewModel.hasChanges { Text("Tap 'Save' to save the new order.") }
            }
        }
        .environment(\.editMode, .constant(.active))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") { viewModel.saveOrder(); dismiss() }
                .disabled(!viewModel.hasChanges)
        }
        ToolbarItem(placement: .navigationBarLeading) {
            if viewModel.hasChanges {
                Button("Reset") { viewModel.resetOrder() }
            } else {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Deletion helpers
    private func beginDelete(_ group: AccountGroup) {
        accountToDelete = group
        let hasOath = !group.oathCredentials.isEmpty
        let hasPush = !group.pushCredentials.isEmpty
        if hasOath && hasPush {
            deleteType = nil
        } else if hasOath {
            deleteType = .oathOnly
        } else {
            deleteType = .pushOnly
        }
    }

    private func performDelete() {
        guard let account = accountToDelete, let type = deleteType else { return }
        accountToDelete = nil
        deleteType = nil
        Task { await viewModel.deleteAccount(account, deleteOath: type == .oathOnly || type == .both, deletePush: type == .pushOnly || type == .both) }
    }


}

// MARK: - Account Row View
private struct AccountRowView: View {
    let group: AccountGroup
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(group.displayIssuer)
                    .font(.headline)

                Text(group.displayAccountName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        let hasOath = !group.oathCredentials.isEmpty
        let hasPush = !group.pushCredentials.isEmpty

        if hasOath && hasPush {
            return "person.badge.shield.checkmark.fill"
        } else if hasPush {
            return "bell.fill"
        } else {
            return "timer"
        }
    }
}

#Preview {
    NavigationView {
        EditAccountsScreen(
            accountGroups: [
                AccountGroup(
                    issuer: "example.com",
                    accountName: "user1@example.com",
                    displayIssuer: "Example Service",
                    displayAccountName: "user1@example.com",
                    oathCredentials: [],
                    pushCredentials: []
                ),
                AccountGroup(
                    issuer: "test.com",
                    accountName: "user2@test.com",
                    displayIssuer: "Test Service",
                    displayAccountName: "user2@test.com",
                    oathCredentials: [],
                    pushCredentials: []
                )
            ]
        )
    }
}
