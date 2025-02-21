//
//  ContentView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// The main application entry point.
@main
struct MyApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

/// The main view of the application, displaying navigation options and a logo.
struct ContentView: View {
  /// State variable to track if Davinci has started.
  @State private var startDavinici = false
  /// State variable for managing the navigation stack path.
  @State private var path: [String] = []
  
  var body: some View {
    
    NavigationStack(path: $path) {
      List {
        /// Navigation option to launch the Davinci feature.
        NavigationLink(value: "DaVinci") {
          Text("Launch DaVinci")
        }
        /// Navigation option to access the token-related view.
        NavigationLink(value: "Token") {
          Text("Access Token")
        }
        /// Navigation option to access user information.
        NavigationLink(value: "User") {
          Text("User Info")
        }
        /// Navigation option to logout.
        NavigationLink(value: "Logout") {
          Text("Logout")
        }
      }.navigationDestination(for: String.self) { item in
        switch item {
        case "DaVinci":
          DavinciView(path: $path)
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
      Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
        .padding(.vertical, 32)
    }
  }
}
