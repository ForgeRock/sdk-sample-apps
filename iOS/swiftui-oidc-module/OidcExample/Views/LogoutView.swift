//
//  LogoutView.swift
//  OidcExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
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
        VStack(spacing: 20) {
            Spacer()

            if !logoutViewModel.logoutStatus.isEmpty {
                Text(logoutViewModel.logoutStatus)
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }

            Button(action: {
                Task {
                    await logoutViewModel.logout()
                    // Navigate back to the login screen
                    path.removeAll()
                    path.append("OidcLogin")
                }
            }) {
                Text("Proceed to Logout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.red)
                    .cornerRadius(15.0)
                    .shadow(radius: 10.0, x: 20, y: 10)
            }

            Spacer()
        }
        .navigationTitle("Logout")
    }
}
