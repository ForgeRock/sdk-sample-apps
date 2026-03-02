//
//  EditAccountDialog.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A sheet dialog for editing an account's display issuer and display account name.
struct EditAccountDialog: View {
    let account: AccountGroup
    let onDismiss: () -> Void
    let onConfirm: (String, String) -> Void

    @State private var displayIssuer: String
    @State private var displayAccountName: String

    init(account: AccountGroup, onDismiss: @escaping () -> Void, onConfirm: @escaping (String, String) -> Void) {
        self.account = account
        self.onDismiss = onDismiss
        self.onConfirm = onConfirm
        _displayIssuer = State(initialValue: account.displayIssuer)
        _displayAccountName = State(initialValue: account.displayAccountName)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Display Name")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Issuer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Display Issuer", text: $displayIssuer)
                            .textContentType(.organizationName)
                            .autocorrectionDisabled()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Display Account Name", text: $displayAccountName)
                            .textContentType(.username)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                    }
                }

                Section(footer: Text("Changing the display name does not affect the underlying account identity.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onConfirm(displayIssuer.trimmingCharacters(in: .whitespaces),
                                  displayAccountName.trimmingCharacters(in: .whitespaces))
                    }
                    .disabled(displayIssuer.trimmingCharacters(in: .whitespaces).isEmpty ||
                              displayAccountName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
