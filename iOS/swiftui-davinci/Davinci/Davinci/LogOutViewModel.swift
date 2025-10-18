//
//  LogOutViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
/// A view model responsible for managing the logout functionality.
/// - Handles the logout process for the user and updates the state for UI display.
@MainActor
class LogOutViewModel: ObservableObject {
    /// A published property that holds the status of the logout process.
    /// - Updated with a completion message when logout is successful.
    @Published var logout: String = ""
    
    /// Performs the user logout process using either the DaVinci SDK or OIDC Web SDK.
    /// - Executes the appropriate `logout()` method based on which user is authenticated.
    /// - Updates the `logout` property with a completion message upon success.
    func logout() async {
        var logoutMessage = ""
        
        /// Check for DaVinci user first
        if let daVinciUser = await daVinci.daVinciUser() {
            await daVinciUser.logout()
            logoutMessage = "DaVinci user logout completed"
        }
        /// Check for OIDC user
        if let oidcUser = await oidcLogin.oidcLoginUser() {
            await oidcUser.logout()
            logoutMessage = "OIDC user logout completed"
        }
        /// If no authenticated user found
        else {
            logoutMessage = "No authenticated user found"
        }
        
        /// Update the UI on the main thread
        await MainActor.run {
            logout = logoutMessage
        }
    }
}
