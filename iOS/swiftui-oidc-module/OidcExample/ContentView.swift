//
//  ContentView.swift
//  OidcExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// The main view of the application, displaying navigation options and a logo.
/// - Provides navigation links to various features of the application.
struct ContentView: View {
    /// State variable for managing the navigation stack path.
    /// - Keeps track of the navigation hierarchy for proper navigation flow.
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: PingTheme.Spacing.large) {
                    headerSection

                    VStack(spacing: PingTheme.Spacing.large) {
                        sectionCard("Authentication", items: [
                            MenuItem(icon: "person.badge.key.fill", title: "Launch OIDC Login",
                                     subtitle: "Start the OIDC authorization code flow", destination: "OidcLogin"),
                        ])

                        sectionCard("User Data", items: [
                            MenuItem(icon: "key.fill", title: "Access Token",
                                     subtitle: "Inspect the current access token", destination: "Token"),
                            MenuItem(icon: "person.circle.fill", title: "User Info",
                                     subtitle: "Details about the authenticated user", destination: "User"),
                        ])

                        sectionCard("Session Management", items: [
                            MenuItem(icon: "rectangle.portrait.and.arrow.right", title: "Logout",
                                     subtitle: "Sign out of the current session", destination: "Logout"),
                        ])
                    }
                    .padding(.horizontal, PingTheme.Spacing.screen)
                }
                .padding(.bottom, PingTheme.Spacing.scrollBottomInset)
            }
            .pingScreenBackground()
            .navigationDestination(for: String.self) { item in
                /// Routes to different views based on the selected navigation option
                switch item {
                case "OidcLogin":
                    OidcLoginView(path: $path)
                case "Token":
                    AccessTokenView()
                case "User":
                    UserInfoView()
                case "Logout":
                    LogoutView(path: $path)
                default:
                    EmptyView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header Section

    /// Full-bleed branded hero banner: the gradient shape is repartnered with
    /// the dynamic action colors so the foreground contrast holds in dark mode.
    private var headerSection: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [PingTheme.Color.actionPrimary, PingTheme.Color.actionPrimaryPressed],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: PingTheme.Spacing.medium) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Text("Orchestration SDK")
                    .font(PingTheme.Typography.display)
                    .foregroundColor(PingTheme.Color.actionPrimaryForeground)

                Text("OIDC Module Sample")
                    .font(PingTheme.Typography.supporting.weight(.medium))
                    .foregroundColor(PingTheme.Color.actionPrimaryForeground.opacity(0.9))
            }
            .padding(.vertical, PingTheme.Spacing.large)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Section Card

    private func sectionCard(_ title: String, items: [MenuItem]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(PingTheme.Typography.supporting.weight(.semibold))
                .foregroundStyle(PingTheme.Color.contentSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, PingTheme.Spacing.medium)
                .padding(.bottom, PingTheme.Spacing.small)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.destination) { index, item in
                    menuItemButton(item)

                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, PingTheme.Control.infoRowDividerInset - PingTheme.Control.fieldPadding)
                    }
                }
            }
            .pingCardStyle(size: .rowList)
        }
    }

    // MARK: - Menu Item Button

    private func menuItemButton(_ item: MenuItem) -> some View {
        NavigationLink(value: item.destination) {
            HStack(spacing: PingTheme.Spacing.medium) {
                PingIconTile(systemName: item.icon, diameter: 40, iconSize: 20)

                VStack(alignment: .leading, spacing: PingTheme.Spacing.xxSmall) {
                    Text(item.title)
                        .font(PingTheme.Typography.body.weight(.medium))
                        .foregroundStyle(PingTheme.Color.contentPrimary)

                    Text(item.subtitle)
                        .pingSupportingText()
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PingTheme.Color.contentSecondary)
            }
            .padding(.vertical, PingTheme.Spacing.small)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// A single main-menu row: icon tile, title, subtitle, and a navigation
/// destination identifier.
private struct MenuItem: Identifiable {
    let icon: String
    let title: String
    let subtitle: String
    let destination: String

    var id: String { destination }
}
