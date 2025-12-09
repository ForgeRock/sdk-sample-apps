//
//  UserInfoView.swift
//  OidcExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

/// A view that displays user information.
/// - Presents the user's profile information retrieved from the authentication provider.
struct UserInfoView: View {
    /// A state object that manages the user information data.
    /// - The `UserInfoViewModel` is responsible for fetching and updating user data.
    @StateObject var userInfoViewModel = UserInfoViewModel()

    var body: some View {
        /// Scrollable container for user information
        ScrollView {
            /// Display the user information text with secondary styling
            Text($userInfoViewModel.userInfo.wrappedValue)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .navigationTitle("User Info")
        }
    }
}
