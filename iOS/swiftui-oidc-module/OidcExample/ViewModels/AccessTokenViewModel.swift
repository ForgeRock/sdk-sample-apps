//
//  AccessTokenViewModel.swift
//  OidcExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import PingLogger
import PingOidc

/// The OIDC client whose token the access token screen shows.
enum TokenSource {
    /// The standard client, `oidcLogin`.
    case standard
    /// The Rich Authorization Requests client held by `RarClientStore`, which keeps its token in its own storage.
    case rar
}

/// A view model responsible for managing the access token state.
/// - This class handles fetching the access token using the OIDC SDK and logs the results.
/// - Provides an observable published property for UI updates.
@MainActor
class AccessTokenViewModel: ObservableObject {
    /// Published property to hold the current access token.
    /// - Updates are published to the UI whenever the value changes.
    @Published var accessToken: String = ""

    /// The `authorization_details` granted for the current token.
    /// - `nil` when the token response carried none (or none has been loaded), empty when the
    ///   server returned an empty array.
    @Published var authorizationDetails: [AuthorizationDetail]?

    /// Whether `accessToken` holds a loaded token rather than a status or error message.
    @Published private(set) var hasToken: Bool = false

    /// The client whose token is shown.
    let source: TokenSource

    /// Initializes the `AccessTokenViewModel` and fetches the access token asynchronously.
    /// - Triggers the token fetch process immediately upon initialization.
    /// - Parameter source: The client whose token is shown. Defaults to the standard client.
    init(source: TokenSource = .standard) {
        self.source = source
        Task {
            await fetchAccessToken()
        }
    }

    /// Fetches the access token using the OIDC SDK.
    /// - The method checks for a successful token retrieval and updates the `accessToken` property.
    /// - Logs the success or failure result using `PingLogger`.
    func fetchAccessToken() async {
        /// Request the token from the OIDC SDK
        let token = await currentUser()?.token()

        /// Process the token result
        switch token {
        case .success(let accessToken):
            /// Update the UI on the main thread with the received token
            await MainActor.run {
                self.accessToken = String(describing: accessToken)
                self.authorizationDetails = accessToken.authorizationDetails
                self.hasToken = true
            }
            /// Log the successful token retrieval
            switch source {
            case .standard:
                LogManager.standard.i("AccessToken: \(self.accessToken)")
            case .rar:
                // Only the number of granted details is logged, never the token or the details.
                LogManager.standard.i("RAR AccessToken retrieved, granted authorization_details: \(accessToken.authorizationDetails?.count ?? 0)")
            }
        case .failure(let error):
            /// Update the UI on the main thread with the error message
            await MainActor.run {
                self.accessToken = "Error: \(error.localizedDescription)"
                self.authorizationDetails = nil
                self.hasToken = false
            }
            /// Log the error that occurred
            LogManager.standard.e("", error: error)
        case .none:
            /// No response received, no further action required
            await MainActor.run {
                self.accessToken = "No user session found. Please login first."
                self.authorizationDetails = nil
                self.hasToken = false
            }
        }
    }

    /// Revokes the RAR token and clears it from this screen.
    /// - Only meaningful for the `.rar` source, and a no-op for any other.
    /// - Revokes at the server and clears the RAR client's own storage; the standard client's
    ///   token and the browser session are not affected.
    func revokeRarToken() async {
        guard source == .rar else { return }

        guard let user = await currentUser() else {
            accessToken = "No user session found. Please login first."
            authorizationDetails = nil
            hasToken = false
            return
        }

        await user.revoke()
        LogManager.standard.i("RAR token revoked")

        accessToken = "RAR token revoked. A new RAR login is required."
        authorizationDetails = nil
        hasToken = false
    }

    // MARK: - Private

    /// The user of the client selected by `source`.
    ///
    /// The RAR client is read from `RarClientStore` on every call because the store replaces it
    /// when its options change.
    private func currentUser() async -> User? {
        switch source {
        case .standard:
            return await oidcLogin.oidcLoginUser()
        case .rar:
            return await RarClientStore.shared.client.oidcLoginUser()
        }
    }
}
