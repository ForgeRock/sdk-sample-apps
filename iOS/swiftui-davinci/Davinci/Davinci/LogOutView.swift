//
//  LogOutView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view for managing the logout process.
struct LogOutView: View {
    /// A binding to the navigation stack path.
    @Binding var path: [String]
    /// State object for managing the logout functionality.
    @StateObject private var logoutViewModel = LogOutViewModel()

    var body: some View {
        VStack(spacing: PingTheme.Spacing.large) {
            Spacer()

            Text("Proceed to sign out of the current session.")
                .pingSupportingText()
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await logoutViewModel.logout()
                    path.removeLast()
                    path.append("DaVinci")
                }
            } label: {
                Label("Proceed to Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.pingDestructive)

            if !logoutViewModel.logout.isEmpty {
                Text(logoutViewModel.logout)
                    .pingSupportingText()
            }

            Spacer()
        }
        .padding(.horizontal, PingTheme.Spacing.screen)
        .pingScreenBackground()
        .navigationTitle("Logout")
        .navigationBarTitleDisplayMode(.inline)
    }
}
