//
//  UserInfoViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingLogger
import PingOrchestrate
import PingOidc

/// A view model responsible for fetching and managing user information.
/// - Provides a published `userInfo` property that is updated with user information or error messages.
/// - Fetches user data asynchronously using the DaVinci SDK.
@MainActor
class UserInfoViewModel: ObservableObject {
    /// Published property to hold the user information or error messages.
    /// - Updated when user information is successfully retrieved or when an error occurs.
    @Published var userInfo: String = ""
    
    /// Initializes the `UserInfoViewModel` and fetches user information.
    /// - The data is fetched asynchronously during initialization.
    init() {
        Task {
            await fetchUserInfo()
        }
    }
    
    /// Fetches user information from either the DaVinci SDK or OIDC Web SDK.
    /// - The method retrieves user details as a dictionary and formats them as a string for display.
    /// - Updates the `userInfo` property with the fetched data or an error message.
    /// - Logs success and error messages using `PingLogger`.
    func fetchUserInfo() async {
        var userInfoResult: Result<UserInfo, OidcError>?
        
        /// Check DaVinci user first
        if let daVinciUser = await daVinci.daVinciUser() {
            userInfoResult = await daVinciUser.userinfo(cache: false)
            LogManager.standard.i("Fetching user info from DaVinci user")
        }
        /// If no DaVinci user, check OIDC user
        else if let oidcUser = await oidcLogin.user() {
            userInfoResult = await oidcUser.userinfo(cache: false)
            LogManager.standard.i("Fetching user info from OIDC user")
        }
        
        switch userInfoResult {
        case .success(let userInfoDictionary):
            // On success, format the dictionary into a string and update `userInfo`.
            await MainActor.run {
                var userInfoDescription = ""
                userInfoDictionary.forEach { userInfoDescription += "\($0): \($1)\n" }
                self.userInfo = userInfoDescription
            }
            LogManager.standard.i("User info retrieved successfully")
        case .failure(let error):
            // On failure, update `userInfo` with an error message.
            await MainActor.run {
                self.userInfo = "Failed to get user info: \(error.localizedDescription)"
            }
            LogManager.standard.e("Failed to get user info: \(error)", error: error)
        case .none:
            await MainActor.run {
                self.userInfo = "No authenticated user found"
            }
            LogManager.standard.w("No authenticated user found", error: nil)
        }
    }
}
