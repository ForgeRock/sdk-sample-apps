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

/// A view model responsible for managing the access token state.
/// - This class handles fetching the access token using the DaVinci SDK and logs the results.
/// - Provides an observable published property for UI updates.
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
    
    /// Fetches the access token using the DaVinci SDK.
    /// - The method checks for a successful token retrieval and updates the `accessToken` property.
    /// - Logs the success or failure result using `PingLogger`.
    func accessToken() async {
        /// Request the token from the DaVinci SDK
        let token = await davinci.user()?.token()
        
        /// Process the token result
        switch token {
        case .success(let accessToken):
            /// Update the UI on the main thread with the received token
            await MainActor.run {
                self.accessToken = String(describing: accessToken)
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
            /// No response received, no further action required
            break
        }
    }
}
