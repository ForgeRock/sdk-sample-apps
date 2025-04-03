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
    
    /// Performs the user logout process using the DaVinci SDK.
    /// - Executes the `logout()` method from the DaVinci user object asynchronously.
    /// - Updates the `logout` property with a completion message upon success.
    func logout() async {
        /// Call the DaVinci SDK's logout method
        await davinci.user()?.logout()
        /// Update the UI on the main thread
        await MainActor.run {
            logout =  "Logout completed"
        }
    }
}
