//
//  AccessTokenViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingLogger
import PingJourney
import PingOidc
import Combine

/// A view model responsible for managing the access token state.
/// - This class handles fetching the access token using the DaVinci SDK and logs the results.
/// - Provides an observable published property for UI updates.
@MainActor
class AccessTokenViewModel: ObservableObject {
    /// Published property to hold the current access token.
    /// - Updates are published to the UI whenever the value changes.
    @Published var token: String = ""
    
    /// Initializes the `TokenViewModel` and fetches the access token asynchronously.
    init() {
        Task {
            await accessToken()
        }
    }
    
    /// Fetches the access token using the DaVinci SDK.
    /// - The method checks for a successful token retrieval and updates the `accessToken` property.
    /// - Logs the success or failure result using `PingLogger`.
    func accessToken() async {
        let token: Result<Token, OidcError>? = await journey.journeyUser()?.token()

        switch token {
        case .success(let token):
            await MainActor.run {
                self.token = String(describing: token)
            }
            LogManager.standard.i("AccessToken: \(self.token)")
        case .failure(let error):
            await MainActor.run {
                self.token = "Error: \(error.localizedDescription)"
            }
            LogManager.standard.e("", error: error)
        case .none:
            break
        }
    }
}
