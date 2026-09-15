//
//  LogoutView.swift
//  OidcExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view for managing the logout process.
struct LogoutView: View {
    /// A binding to the navigation stack path.
    @Binding var path: [String]
    /// State object for managing the logout functionality.
    @StateObject private var logoutViewModel = LogoutViewModel()

    var body: some View {
        VStack(spacing: PingTheme.Spacing.large) {
            Spacer()

            Text("Proceed to sign out of the current session. You will be returned to the login screen.")
                .pingSupportingText()
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await logoutViewModel.logout()
                    // Navigate back to the login screen
                    path.removeAll()
                    path.append("OidcLogin")
                }
            } label: {
                Label("Proceed to Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.pingDestructive)

            Spacer()
        }
        .padding(.horizontal, PingTheme.Spacing.screen)
        .pingScreenBackground()
        .navigationTitle("Logout")
        .navigationBarTitleDisplayMode(.inline)
    }
}
