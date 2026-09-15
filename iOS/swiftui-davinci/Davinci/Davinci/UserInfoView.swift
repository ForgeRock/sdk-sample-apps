//
//  UserInfoView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
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
            userInfoCard
                .padding(.horizontal, PingTheme.Spacing.screen)
                .padding(.top, PingTheme.Spacing.medium)
                .padding(.bottom, PingTheme.Spacing.scrollBottomInset)
        }
        .pingScreenBackground()
        .navigationTitle("User Info")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - User Info Card

    private var userInfoCard: some View {
        let pairs = parseUserInfo(userInfoViewModel.userInfo)
        return VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: "person.fill", diameter: 40, iconSize: 20)

                Text("User Info")
                    .pingSectionHeader()

                Spacer()
            }

            Divider()

            if pairs.isEmpty {
                Text(userInfoViewModel.userInfo)
                    .pingSupportingText()
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                    ForEach(pairs, id: \.key) { pair in
                        PingInfoRow(
                            label: pair.key,
                            value: pair.value,
                            layout: .vertical,
                            valueStyle: .monospaced
                        )
                    }
                }
            }
        }
        .pingCardStyle()
    }

    /// Parses `key: value` lines into labeled rows; returns empty when the
    /// text isn't parseable (error or no-session strings render as-is).
    private func parseUserInfo(_ info: String) -> [(key: String, value: String)] {
        info.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { return nil }
            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, !value.isEmpty else { return nil }
            return (key, value)
        }
    }
}
