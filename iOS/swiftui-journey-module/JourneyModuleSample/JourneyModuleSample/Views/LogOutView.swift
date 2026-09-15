//
//  LogOutView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view for managing the logout process.
struct LogOutView: View {
    /// A binding to the navigation stack path.
    @Binding var path: [MenuItem]
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
                    if path.count > 0 {
                        path.removeLast()
                    }
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
        .navigationTitle(path.last?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
}
