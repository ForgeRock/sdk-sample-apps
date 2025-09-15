//
//  ContentView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// The main application entry point.
/// - Serves as the application's launch point and provides the main scene.
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            /// Present the ContentView as the root view of the application
            ContentView()
        }
    }
}

/// The main view of the application, displaying navigation options and a logo.
/// - Provides navigation links to various features of the application.
struct ContentView: View {
    /// State variable to track if Davinci has started.
    /// - Used to control the initialization of the Davinci authentication flow.
    @State private var startDavinci = false
    /// State variable for managing the navigation stack path.
    /// - Keeps track of the navigation hierarchy for proper navigation flow.
    @State private var path: [String] = []
    
    var body: some View {
        
        NavigationStack(path: $path) {
            List {
                /// Navigation option to launch the Davinci feature.
                /// - Takes the user to the DaVinci authentication flow.
                NavigationLink(value: "DaVinci") {
                    Text("Launch DaVinci")
                }
                /// Navigation option to launch OIDC login.
                /// - Takes the user to the OIDC Web authentication flow.
                NavigationLink(value: "OIDC") {
                    Text("Launch OIDC Login")
                }
                /// Navigation option to access the token-related view.
                /// - Shows the user's current access token.
                NavigationLink(value: "Token") {
                    Text("Access Token")
                }
                /// Navigation option to access user information.
                /// - Displays details about the authenticated user.
                NavigationLink(value: "User") {
                    Text("User Info")
                }
                /// Navigation option to logout.
                /// - Allows the user to sign out of their current session.
                NavigationLink(value: "Logout") {
                    Text("Logout")
                }
            }.navigationDestination(for: String.self) { item in
                /// Routes to different views based on the selected navigation option
                switch item {
                case "DaVinci":
                    DavinciView(path: $path)
                case "OIDC":
                    OidcLoginView(path: $path)
                case "Token":
                    AccessTokenView()
                case "User":
                    UserInfoView()
                case "Logout":
                    LogOutView(path: $path)
                default:
                    EmptyView()
                }
            }.navigationBarTitle("DaVinci")
            Spacer()
            /// Application logo displayed at the bottom of the screen
            Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
                .padding(.vertical, 32)
        }
    }
}
