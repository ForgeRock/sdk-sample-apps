//
//  RarLoginView.swift
//  OidcExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOidc
import PingOrchestrate
import SwiftUI

/// View that exercises RFC 9396 Rich Authorization Requests on the OIDC login flow:
/// edit `authorization_details` JSON, choose the delivery path and PAR, run the login,
/// and see the outcome before inspecting the RAR token.
struct RarLoginView: View {
    /// The view model that manages the RAR login flow logic.
    @StateObject private var viewModel = RarLoginViewModel()
    /// A binding to the navigation stack path.
    @Binding var path: [String]

    var body: some View {
        Group {
            if viewModel.isLoading {
                PingLoadingOverlay()
            } else if let state = viewModel.state {
                switch state {
                case .success:
                    resultCard(
                        icon: "checkmark.circle.fill",
                        tint: PingTheme.Color.statusSuccess,
                        title: "Authorization Successful!",
                        message: "The login completed with the configured authorization_details. The granted details are on the RAR token."
                    ) {
                        Button {
                            path.append("RarToken")
                        } label: {
                            Label("View RAR Access Token", systemImage: "checkmark.shield.fill")
                        }
                        .buttonStyle(.pingPrimary)
                    }

                case .failure(let error):
                    resultCard(
                        icon: "xmark.circle.fill",
                        tint: PingTheme.Color.statusError,
                        title: "Authorization Failed",
                        message: error.displayMessage
                    ) {
                        Button {
                            Task { await viewModel.login() }
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
        .navigationTitle("RAR Login")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Idle

    private var idleCard: some View {
        ScrollView {
            VStack(spacing: PingTheme.Spacing.large) {
                statusCard

                presetPicker

                jsonEditor

                parToggle

                deliveryPicker

                loginButton
            }
            .pingScrollContentPadding(top: PingTheme.Spacing.medium)
        }
    }

    // MARK: - Status Card

    /// The current PAR and delivery choice, plus the two caveats that read differently from
    /// what the controls suggest: the RAR token is held apart from the standard token, and PAR
    /// only changes the flow when discovery advertises a PAR endpoint.
    private var statusCard: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: "checkmark.shield", diameter: 40, iconSize: 20)

                Text("Rich Authorization Requests")
                    .pingSectionHeader()

                Spacer()
            }

            Divider()

            PingInfoRow(label: "PAR", value: viewModel.parEnabled ? "On" : "Off")
            PingInfoRow(label: "Delivery", value: viewModel.delivery.displayName)

            Divider()

            Text("The RAR token is stored separately; a new RAR login revokes only the previous RAR token.")
                .pingSupportingText()

            Text("PAR applies only when the discovery document advertises a PAR endpoint.")
                .pingSupportingText()
        }
        .pingCardStyle()
    }

    // MARK: - Preset Picker

    private var presetPicker: some View {
        TabPicker(
            selection: $viewModel.preset,
            label: { $0.rawValue },
            icon: { _ in "doc.text" },
            onSelect: { preset in
                viewModel.selectPreset(preset)
            },
            isDisabled: viewModel.isLoading
        )
    }

    // MARK: - JSON Editor

    private var jsonEditor: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text("authorization_details (JSON array)")
                .pingSectionHeader()

            TextEditor(text: Binding(
                get: { viewModel.jsonText },
                set: { viewModel.updateJsonText($0) }
            ))
                .font(PingTheme.Typography.monospacedCaption)
                .frame(minHeight: 180)
                .scrollContentBackground(.hidden)
                .pingTextFieldStyle(showsError: viewModel.validationError != nil)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .disabled(viewModel.isLoading)
                .accessibilityLabel("authorization_details JSON")

            if let error = viewModel.validationError {
                Text(error)
                    .font(PingTheme.Typography.supporting)
                    .foregroundStyle(PingTheme.Color.statusError)
            } else if let details = viewModel.decodedDetails() {
                Text("Valid — \(details.count) object(s).")
                    .font(PingTheme.Typography.supporting)
                    .foregroundStyle(PingTheme.Color.statusSuccess)
            }
        }
    }

    // MARK: - PAR Toggle

    private var parToggle: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.xSmall) {
            Toggle("Pushed Authorization Requests (PAR)", isOn: $viewModel.parEnabled)
                .disabled(viewModel.isLoading)

            Text("When on, the authorization parameters are pushed to the server before the redirect (RFC 9126).")
                .pingSupportingText()
        }
        .pingCardStyle()
    }

    // MARK: - Delivery Picker

    private var deliveryPicker: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text("Delivery")
                .pingSectionHeader()

            Picker("Delivery", selection: $viewModel.delivery) {
                ForEach(RarLoginViewModel.Delivery.allCases) { delivery in
                    Text(delivery.displayName).tag(delivery)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isLoading)

            Text("Per transaction sends the details for this login only; client config sets them on the client for every login. A per-transaction value wins over a config-level one.")
                .pingSupportingText()
        }
        .pingCardStyle()
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button {
            Task { await viewModel.login() }
        } label: {
            Label("Login with authorization_details", systemImage: "checkmark.shield")
        }
        .buttonStyle(.pingPrimary)
        .disabled(viewModel.decodedDetails() == nil || viewModel.isLoading)
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
