//
//  OidcLoginViewModel.swift
//  OidcExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOrchestrate
import PingOidc
import PingLogger
import PingBrowser
import Combine

/// Configures and initializes the OIDC Web instance with OAuth 2.0 client details.
/// - This configuration includes:
///   - Client ID
///   - Scopes
///   - Redirect URI
///   - Discovery Endpoint
///   - Browser settings
public let oidcLogin = OidcWebClient.createOidcWebClient { config in
    //TODO: Provide here the Server configuration. Add the PingOne/PingAM Discovery Endpoint and the OAuth2.0 client details
    config.browserMode = .login
    config.browserType = .authSession
    config.logger = LogManager.standard

    config.module(PingOidc.OidcModule.config) { oidcValue in
        oidcValue.clientId = <#"Client ID"#>
        oidcValue.scopes = Set([<#"openid"#>, <#"profile"#>, <#"email"#>])
        oidcValue.redirectUri = <#"Redirect URI"#>
        oidcValue.discoveryEndpoint = <#"Discovery Endpoint"#>
        // Optional: Add ACR values if required by your authentication flow
        // oidcValue.acrValues = <#"ACR_VALUE"#>
    }
}

/// A view model that manages the OIDC authentication flow and state.
/// - Responsible for:
///   - Starting the OIDC authorization flow
///   - Managing authentication state (success/failure)
///   - Handling loading states
@MainActor
class OidcLoginViewModel: ObservableObject {
    /// Published property that holds the current authentication state.
    @Published public var state: Result<User, OidcError>?
    /// Published property to track whether the view is currently loading.
    @Published public var isLoading: Bool = false

    /// Initializes the view model (does not auto-start the flow).
    init() {
        // Initialization only - authentication is triggered manually
    }

    /// Starts the OIDC authorization flow.
    /// - This initiates browser-based authentication and returns the result.
    public func startOidcLogin() async {
        await MainActor.run {
            isLoading = true
        }

        do {
            // Start the OIDC authorization flow
            let result = try await oidcLogin.authorize { options in
                // Optional: Add additional parameters to the authorization request
                // options.additionalParameters = ["key": "value"]
            }

            await MainActor.run {
                self.state = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                if let oidcError = error as? OidcError {
                    self.state = .failure(oidcError)
                } else {
                    // Wrap generic errors in OidcError if needed
                    self.state = .failure(.unknown())
                }
                isLoading = false
            }
        }
    }
}
