//
//  AccessTokenView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view that displays the current access token.
struct AccessTokenView: View {
    let menuItem: MenuItem
    @StateObject private var accessTokenViewModel = AccessTokenViewModel()

    var body: some View {
        ScrollView {
            tokenCard
                .padding(.horizontal, PingTheme.Spacing.screen)
                .padding(.top, PingTheme.Spacing.medium)
                .padding(.bottom, PingTheme.Spacing.scrollBottomInset)
        }
        .pingScreenBackground()
        .navigationTitle(menuItem.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Token Card

    private var tokenCard: some View {
        let pairs = parseTokenInfo(accessTokenViewModel.token)
        return VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: menuItem.icon, diameter: 40, iconSize: 20)

                Text("Access Token")
                    .pingSectionHeader()

                Spacer()

                Button {
                    UIPasteboard.general.string = accessTokenViewModel.token
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: PingTheme.Control.Glyph.small))
                        .foregroundColor(PingTheme.Color.actionPrimary)
                }
                .accessibilityLabel("Copy access token")
            }

            Divider()

            if pairs.isEmpty {
                Text(accessTokenViewModel.token)
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

    /// Parses `key: value` lines (the SDK's `Token.description` shape) into
    /// labeled rows; returns empty when the text isn't parseable.
    private func parseTokenInfo(_ info: String) -> [(key: String, value: String)] {
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
