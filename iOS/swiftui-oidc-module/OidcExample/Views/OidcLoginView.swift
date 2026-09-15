//
//  OidcLoginView.swift
//  OidcExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOrchestrate

/// View that handles OIDC login flow and displays authentication state.
struct OidcLoginView: View {
    /// The view model that manages the OIDC login flow logic.
    @StateObject private var oidcLoginViewModel = OidcLoginViewModel()
    /// A binding to the navigation stack path.
    @Binding var path: [String]

    var body: some View {
        Group {
            if oidcLoginViewModel.isLoading {
                PingLoadingOverlay()
            } else if let state = oidcLoginViewModel.state {
                switch state {
                case .success:
                    resultCard(
                        icon: "checkmark.circle.fill",
                        tint: PingTheme.Color.statusSuccess,
                        title: "Authentication Successful!",
                        message: "User authenticated."
                    ) {
                        Button {
                            path.append("Token")
                        } label: {
                            Label("View Access Token", systemImage: "key.fill")
                        }
                        .buttonStyle(.pingPrimary)
                    }

                case .failure(let error):
                    resultCard(
                        icon: "xmark.circle.fill",
                        tint: PingTheme.Color.statusError,
                        title: "Authentication Failed",
                        message: error.localizedDescription
                    ) {
                        Button {
                            Task { await oidcLoginViewModel.startOidcLogin() }
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.pingPrimary)
                    }
                }
            } else {
                idleCard
            }
        }
        .pingScreenBackground()
        .navigationTitle("OIDC Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Idle

    private var idleCard: some View {
        ScrollView {
            VStack(spacing: PingTheme.Spacing.large) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: PingTheme.Control.Glyph.hero))
                    .foregroundStyle(PingTheme.Color.actionPrimary)

                Text("OIDC Authentication")
                    .pingScreenTitle()

                Text("Tap the button below to start the authorization code flow.")
                    .pingSupportingText()
                    .multilineTextAlignment(.center)

                Button {
                    Task { await oidcLoginViewModel.startOidcLogin() }
                } label: {
                    Label("Start OIDC Login", systemImage: "play.fill")
                }
                .buttonStyle(.pingPrimary)
            }
            .pingScrollContentPadding(top: PingTheme.Spacing.large)
        }
    }

    // MARK: - Result Card

    /// Shared composition for the success and failure outcome states.
    private func resultCard(
        icon: String,
        tint: Color,
        title: String,
        message: String,
        @ViewBuilder actions: () -> some View
    ) -> some View {
        ScrollView {
            VStack(spacing: PingTheme.Spacing.large) {
                Image(systemName: icon)
                    .font(.system(size: PingTheme.Control.Glyph.hero))
                    .foregroundStyle(tint)

                Text(title)
                    .pingScreenTitle()

                Text(message)
                    .pingSupportingText()
                    .multilineTextAlignment(.center)

                actions()
            }
            .pingScrollContentPadding(top: PingTheme.Spacing.large)
        }
    }
}
