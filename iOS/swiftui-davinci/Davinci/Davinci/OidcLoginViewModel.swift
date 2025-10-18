//
//  OidcLoginViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOrchestrate
import PingOidc

/// Creates an OIDC login instance with configuration.
public let oidcLogin = OidcWeb.createOidcWeb { config in
    config.module(PingOidc.OidcModule.config) { oidcValue in
        oidcValue.clientId = "<#CLIENT_ID#>"
        oidcValue.scopes = Set(["openid", "email", "address", "phone", "profile"])
        oidcValue.redirectUri = "<#REDIRECT_URI#>"
        oidcValue.acrValues = "<#ACR_VALUES#>"
        oidcValue.discoveryEndpoint = "<#DISCOVERY_ENDPOINT#>"
    }
}

/// A view model that manages the flow and state of the OIDC login process.
/// - Responsible for:
///   - Starting the OIDC login flow
///   - Managing the authentication state
///   - Handling success and failure cases
@MainActor
class OidcLoginViewModel: ObservableObject {
    /// Published property that holds the current authentication state.
    @Published public var state: Result<User, OidcError>?
    /// Published property to track whether the view is currently loading.
    @Published public var isLoading: Bool = false
    
    /// Starts the OIDC login process.
    /// - Sets the loading state and initiates the authentication flow.
    public func startOidcLogin() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Start the OIDC login process
            let result = try await oidcLogin.authorize { options in
                // Additional parameters can be set here if needed
                options.additionalParameters = [:]
            }
            
            await MainActor.run {
                self.state = result
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.state = .failure(OidcError.unknown(message: error.localizedDescription))
                self.isLoading = false
            }
        }
    }
    
    /// Gets the current OIDC user if available.
    /// - Returns: The current authenticated user or nil.
    public func getOidcUser() async -> User? {
        return await oidcLogin.user()
    }
}
