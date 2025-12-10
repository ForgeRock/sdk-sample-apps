//
//  LogoutViewModel.swift
//  OidcExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import Combine
import PingOidc

/// A view model responsible for managing the logout functionality.
/// - Handles the logout process for the user and updates the state for UI display.
@MainActor
class LogoutViewModel: ObservableObject {
    /// A published property that holds the status of the logout process.
    /// - Updated with a completion message when logout is successful.
    @Published var logoutStatus: String = ""

    /// Performs the user logout process using the OIDC SDK.
    /// - Executes the `logout()` method from the OIDC user object asynchronously.
    /// - Updates the `logoutStatus` property with a completion message upon success.
    func logout() async {
        /// Call the OIDC SDK's logout method
        await oidcLogin.user()?.logout()
        /// Update the UI on the main thread
        await MainActor.run {
            logoutStatus = "Logout completed"
        }
    }
}
