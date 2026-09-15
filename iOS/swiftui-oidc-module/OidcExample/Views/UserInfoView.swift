//
//  UserInfoView.swift
//  OidcExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view that displays user information.
/// - Presents the user's profile information retrieved from the authentication provider.
struct UserInfoView: View {
    /// A state object that manages the user information data.
    /// - The `UserInfoViewModel` is responsible for fetching and updating user data.
    @StateObject var userInfoViewModel = UserInfoViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
                HStack(spacing: PingTheme.Spacing.medium) {
                    PingIconTile(systemName: "person.circle.fill", diameter: 40, iconSize: 20)

                    Text("User Info")
                        .pingSectionHeader()

                    Spacer()
                }

                Divider()

                if userInfoRows.isEmpty {
                    Text(userInfoViewModel.userInfo)
                        .pingSupportingText()
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                        ForEach(userInfoRows, id: \.key) { row in
                            PingInfoRow(
                                label: row.key,
                                value: row.value,
                                layout: .vertical,
                                valueStyle: .monospaced
                            )
                        }
                    }
                }
            }
            .pingCardStyle()
            .padding(.horizontal, PingTheme.Spacing.screen)
            .padding(.top, PingTheme.Spacing.medium)
            .padding(.bottom, PingTheme.Spacing.scrollBottomInset)
        }
        .pingScreenBackground()
        .navigationTitle("User Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The userinfo dictionary as sorted label/value rows, when the raw text
    /// is parseable key/value lines.
    private var userInfoRows: [(key: String, value: String)] {
        userInfoViewModel.userInfo
            .split(separator: "\n")
            .compactMap { line -> (String, String)? in
                guard let idx = line.firstIndex(of: ":") else { return nil }
                let key = String(line[line.startIndex..<idx]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty, !value.isEmpty else { return nil }
                return (key, value)
            }
    }
}
