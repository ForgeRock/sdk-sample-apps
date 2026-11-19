//
//  AccessTokenView.swift
//  OidcExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view that displays the access token.
/// - Provides a simple interface to view the current OAuth access token.
/// - When the token carries granted `authorization_details`, they are listed above the token.
struct AccessTokenView: View {
    /// A state object that manages the access token data.
    /// - Responsible for fetching and maintaining the current access token.
    @StateObject var accessTokenViewModel: AccessTokenViewModel

    /// Creates the view for the token of the given client.
    /// - Parameter source: The client whose token is shown. Defaults to the standard client.
    init(source: TokenSource = .standard) {
        _accessTokenViewModel = StateObject(wrappedValue: AccessTokenViewModel(source: source))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
                if let details = accessTokenViewModel.authorizationDetails, !details.isEmpty {
                    AuthorizationDetailsCard(details: details)
                }

                if let caption = rarStatusCaption {
                    Text(caption)
                        .pingSupportingText()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                tokenCard

                if accessTokenViewModel.source == .rar {
                    revokeButton
                }
            }
            .padding(.horizontal, PingTheme.Spacing.screen)
            .padding(.top, PingTheme.Spacing.medium)
            .padding(.bottom, PingTheme.Spacing.scrollBottomInset)
        }
        .pingScreenBackground()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The screen title and token card heading.
    private var title: String {
        accessTokenViewModel.source == .rar ? "RAR Access Token" : "Access Token"
    }

    // MARK: - Token Card

    private var tokenCard: some View {
        let pairs = parseTokenInfo(accessTokenViewModel.accessToken)
        return VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: "key.fill", diameter: 40, iconSize: 20)

                Text(title)
                    .pingSectionHeader()

                Spacer()

                Button {
                    UIPasteboard.general.string = accessTokenViewModel.accessToken
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: PingTheme.Control.Glyph.small))
                        .foregroundStyle(PingTheme.Color.actionPrimary)
                }
                .accessibilityLabel("Copy access token")
            }

            Divider()

            if pairs.isEmpty {
                Text(accessTokenViewModel.accessToken)
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

    // MARK: - RAR

    /// Explains why no granted-details card is shown for a loaded RAR token, or `nil` when the
    /// card is shown or no token is loaded.
    ///
    /// A missing `authorization_details` member and an empty array are different outcomes: the
    /// first means the server did not process the request as a RAR request, the second that it
    /// did and granted nothing.
    private var rarStatusCaption: String? {
        guard accessTokenViewModel.source == .rar, accessTokenViewModel.hasToken else { return nil }

        guard let details = accessTokenViewModel.authorizationDetails else {
            return "The token response carried no authorization_details."
        }
        if details.isEmpty {
            return "The server returned an empty authorization_details array (no details granted)."
        }
        return nil
    }

    private var revokeButton: some View {
        Button {
            Task { await accessTokenViewModel.revokeRarToken() }
        } label: {
            Label("Revoke RAR Token", systemImage: "xmark.circle")
        }
        .buttonStyle(.pingDestructive)
        .disabled(!accessTokenViewModel.hasToken)
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
