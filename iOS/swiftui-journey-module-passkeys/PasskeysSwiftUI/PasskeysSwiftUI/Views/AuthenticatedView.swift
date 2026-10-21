//
//  AuthenticatedView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import PingOrchestrate

struct AuthenticatedView: View {
    let successNode: SuccessNode
    let onSignOut: () -> Void

    @State private var viewModel = AuthenticatedViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    AuthenticatedHeaderView()

                    VStack(spacing: 20) {
                        profileSection
                        signOutButton
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbarItem }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .onChange(of: viewModel.isSignedOut) { _, signedOut in
                if signedOut { onSignOut() }
            }
            .task {
                await viewModel.loadUserInfo()
            }
        }
    }

    // MARK: - Profile Section

    @ViewBuilder
    private var profileSection: some View {
        if viewModel.isLoadingUserInfo {
            ProgressView("Loading profile…")
                .frame(maxWidth: .infinity)
                .padding(32)
        } else if let errorMessage = viewModel.userInfoError {
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        } else if !viewModel.userInfo.isEmpty {
            UserInfoCard(userInfo: viewModel.userInfo)
        }
    }

    private var signOutButton: some View {
        Button("Sign Out") {
            Task { await viewModel.signOut() }
        }
        .buttonStyle(PingDestructiveButtonStyle())
    }

    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gear")
                    .foregroundColor(.pingRed)
            }
        }
    }
}

// MARK: - Authenticated Header

private struct AuthenticatedHeaderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pingRed, .pingRedDark],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 12) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white.opacity(0.9))

                Text("Authenticated")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 32)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - User Info Card

private struct UserInfoCard: View {
    let userInfo: [String: Any]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Profile")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.bottom, 10)

            VStack(spacing: 0) {
                ForEach(userInfo.keys.sorted(), id: \.self) { key in
                    UserInfoRow(key: key, value: String(describing: userInfo[key] ?? ""))
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

private struct UserInfoRow: View {
    let key: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(key)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)

            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        Divider()
            .padding(.leading, 16)
    }
}

// MARK: - Destructive Button Style

struct PingDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.pingRed)
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(Color.pingRed, lineWidth: 1.5)
                    .opacity(configuration.isPressed ? 0.6 : 1)
            )
    }
}
