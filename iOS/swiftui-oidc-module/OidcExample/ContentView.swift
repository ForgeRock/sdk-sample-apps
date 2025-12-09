//
//  ContentView.swift
//  OidcExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
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
            List {
                Section(header: Text("Authentication")) {
                    /// Navigation option to launch the OIDC login feature.
                    /// - Takes the user to the OIDC authentication flow.
                    NavigationLink(value: "OidcLogin") {
                        HStack {
                            Image(systemName: "person.badge.key.fill")
                                .foregroundColor(.blue)
                            Text("Launch OIDC Login")
                        }
                    }
                }

                Section(header: Text("User Data")) {
                    /// Navigation option to access the token-related view.
                    /// - Shows the user's current access token.
                    NavigationLink(value: "Token") {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundColor(.green)
                            Text("Access Token")
                        }
                    }
                    /// Navigation option to access user information.
                    /// - Displays details about the authenticated user.
                    NavigationLink(value: "User") {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.orange)
                            Text("User Info")
                        }
                    }
                }

                Section(header: Text("Session Management")) {
                    /// Navigation option to logout.
                    /// - Allows the user to sign out of their current session.
                    NavigationLink(value: "Logout") {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Logout")
                        }
                    }
                }
            }
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
            .navigationBarTitle("OIDC Example")

            Spacer()

            /// Application logo displayed at the bottom of the screen
            VStack {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Text("Ping SDKs OIDC Module")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 32)
        }
    }
}
