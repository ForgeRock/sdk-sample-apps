//
//  AccessTokenViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingLogger
import PingOrchestrate
import PingOidc

/// A view model responsible for managing the access token state.
/// - This class handles fetching the access token using the DaVinci SDK and logs the results.
/// - Provides an observable published property for UI updates.
@MainActor
class AccessTokenViewModel: ObservableObject {
    /// Published property to hold the current access token.
    /// - Updates are published to the UI whenever the value changes.
    @Published var accessToken: String = ""
    
    /// Initializes the `AccessTokenViewModel` and fetches the access token asynchronously.
    /// - Triggers the token fetch process immediately upon initialization.
    init() {
        Task {
            await accessToken()
        }
    }
    
    /// Fetches the access token using either the DaVinci SDK or OIDC Web SDK.
    /// - The method checks both daVinci and oidcLogin for an authenticated user and retrieves their token.
    /// - Logs the success or failure result using `PingLogger`.
    func accessToken() async {
        var tokenResult: Result<Token, OidcError>?
        
        /// Check DaVinci user first
        if let daVinciUser = await daVinci.daVinciUser() {
            tokenResult = await daVinciUser.token()
            LogManager.standard.i("Fetching token from DaVinci user")
        }
        /// If no DaVinci user, check OIDC user  
        else if let oidcUser = await oidcLogin.user() {
            tokenResult = await oidcUser.token()
            LogManager.standard.i("Fetching token from OIDC user")
        }
        
        /// Process the token result
        switch tokenResult {
        case .success(let token):
            /// Update the UI on the main thread with the received token
            await MainActor.run {
                self.accessToken = String(describing: token.accessToken)
            }
            /// Log the successful token retrieval
            LogManager.standard.i("AccessToken: \(self.accessToken)")
        case .failure(let error):
            /// Update the UI on the main thread with the error message
            await MainActor.run {
                self.accessToken = "Error: \(error.localizedDescription)"
            }
            /// Log the error that occurred
            LogManager.standard.e("", error: error)
        case .none:
            /// No authenticated user found in either DaVinci or OIDC
            await MainActor.run {
                self.accessToken = "No authenticated user found"
            }
            LogManager.standard.i("No authenticated user found in either DaVinci or OIDC")
        }
    }
}
