//  JourneyViewModel.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOidc
import PingOrchestrate
import PingLogger
import PingStorage
import PingJourney
import Combine

/// Configures and initializes the Journey instance with the AIC/AM server and OAuth 2.0 client details.
/// - This configuration includes:
///   - Client ID
///   - Scopes
///   - Redirect URI
///   - Discovery Endpoint
///   - Other optional fields

public let journey = Journey.createJourney { config in
    config.serverUrl = "https://openam-bafaloukas.forgeblocks.com/am"
    config.realm = "alpha"
    config.cookie = "386c0d288cac4b9"
    config.module(PingJourney.OidcModule.config) { oidcValue in
        oidcValue.clientId = "iosClient"
        oidcValue.scopes = ["openid", "profile", "email"]
        oidcValue.redirectUri = "myapp://callback"
        oidcValue.discoveryEndpoint = "https://openam-bafaloukas.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
    }
}

// MARK: - Multi-User Journey Instances with Separate Session Storage
// The following examples demonstrate how to create multiple Journey instances
// with isolated session and token storage for different users or use cases.
//
// Key points:
// 1. Each Journey instance can have its own cookie storage via SessionModule.config
// 2. Each Journey instance can have its own token storage via OidcModule.config
// 3. Use unique account identifiers to keep storage completely separate
// 4. You must use KeychainStorage<SSOTokenImpl> array type for session storage

/*
// Switch "Journey.createJourney" to "DaVinci.createDaVinci" if required
let userAInstance = Journey.createJourney { config in
    config.serverUrl = "https://example.com/am"
    config.realm = "alpha"

    config.module(SessionModule.config) { sessionConfig in
        sessionConfig.storage = KeychainStorage<SSOTokenImpl>(
            account: "user_a_sessions",
            encryptor: SecuredKeyEncryptor() ?? NoEncryptor()
        )
    }
    
    // Note: Custom session storage configuration is not directly supported
    // via the public API. Session storage uses a default KeychainStorage internally.
    // If you need separate session storage per user, consider using different
    // Journey instances or managing session isolation at a higher level.
    
    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "app-client"
        oidcConfig.discoveryEndpoint = "https://example.com/.well-known/openid-configuration"
        oidcConfig.scopes = ["openid", "profile", "email"]
        oidcConfig.redirectUri = "app:/oauth2redirect"

        // Custom token storage for User A
        oidcConfig.storage = KeychainStorage<Token>(account: "user_a_tokens")
    }
}

// Switch "Journey.createJourney" to "DaVinci.createDaVinci" if required
let userBInstance = Journey.createJourney { config in
    config.serverUrl = "https://example.com/am"
    config.realm = "alpha"

    // Note: Custom session storage configuration is not directly supported
    // via the public API. Session storage uses a default KeychainStorage internally.
    // If you need separate session storage per user, consider using different
    // Journey instances or managing session isolation at a higher level.

    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "app-client"
        oidcConfig.discoveryEndpoint = "https://example.com/.well-known/openid-configuration"
        oidcConfig.scopes = ["openid", "profile", "email"]
        oidcConfig.redirectUri = "app:/oauth2redirect"

        // Custom token storage for User B
        oidcConfig.storage = KeychainStorage<Token>(account: "user_b_tokens")
    }
}


// Instance 1 - Standard authentication with long-lived tokens
// Switch "Journey.createJourney" to "DaVinci.createDaVinci" if required
let standardJourneyInstance = Journey.createJourney { config in
    config.serverUrl = "https://example.com/am"
    config.realm = "alpha"

    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "standard-client"
        oidcConfig.scopes = ["openid", "profile", "email"]
        oidcConfig.redirectUri = "app:/oauth2redirect"

        // Custom storage for this instance’s access tokens
        oidcConfig.storage = KeychainStorage<Token>(account: "standard_tokens")
    }

    // No custom session storage is defined, so it uses the default shared session.
}

// Instance 2 - High-security transactions with short-lived tokens
// Switch "Journey.createJourney" to "DaVinci.createDaVinci" if required
let transactionJourneyInstance2 = Journey.createJourney { config in
    config.serverUrl = "https://example.com/am"
    config.realm = "alpha"

    config.module(PingJourney.OidcModule.config) { oidcConfig in
        oidcConfig.clientId = "transaction-client"
        oidcConfig.scopes = ["openid", "transactions"]
        oidcConfig.redirectUri = "app:/oauth2redirect"

        // Separate storage for this instance’s access token
        oidcConfig.storage = KeychainStorage<Token>(account: "transaction_tokens")
    }

    // Also uses the default shared session storage.
}
 */


// A view model that manages the flow and state of the Journey orchestration process.
/// - Responsible for:
///   - Starting the Journey flow
///   - Progressing to the next node in the flow
///   - Maintaining the current and previous flow state
///   - Handling loading states
@MainActor
class JourneyViewModel: ObservableObject {
    /// Published property that holds the current state node data.
    @Published public var state: JourneyState = JourneyState()
    /// Published property to track whether the view is currently loading.
    @Published public var isLoading: Bool = false
    /// Published property to control whether to show the journey name input screen
    @Published public var showJourneyNameInput: Bool = true

    /// Initializes the view model but does NOT automatically start the journey.
    /// The journey will start when the user enters a journey name.
    init() {
        // Remove auto-start - let user enter journey name first
    }

    /// Starts the Journey orchestration process with a specific journey name.
    /// - Parameter journeyName: The name of the journey to start
    public func startJourney(with journeyName: String) async {
        guard !journeyName.isEmpty else { return }

        await MainActor.run {
            isLoading = true
        }
        
        let next = await journey.start(journeyName) { options in
            options.forceAuth = false
            options.noSession = false
        }

        await MainActor.run {
            self.state = JourneyState(node: next)
            self.showJourneyNameInput = false
            self.isLoading = false
        }
    }

    /// Advances to the next node in the orchestration process.
    /// - Parameter node: The current node to progress from.
    public func next(node: Node) async {
        await MainActor.run {
            isLoading = true
        }
        if let current = node as? ContinueNode {
            // Retrieves the next node in the flow.
            let next = await current.next()
            await MainActor.run {
                self.state = JourneyState(node: next)
                isLoading = false
            }
        }
    }
    
    public func refresh() {
        state = JourneyState(node: state.node)
    }

    /// Reset the view model to show journey name input again
    public func reset() {
        showJourneyNameInput = true
        state = JourneyState()
        isLoading = false
    }

    func getSavedJourneyName() -> String {
        // Retrieve the saved journey name from storage
        UserDefaults.standard.string(forKey: "journeyName") ?? ""
    }

    func saveJourneyName(_ journeyName: String) {
        // Save the journey name to storage
        UserDefaults.standard.set(journeyName, forKey: "journeyName")
    }
}

/// A model class that represents the state of the current and previous nodes in the Journey flow.
class JourneyState {
    var node: Node? = nil

    init(node: Node? = nil) {
        self.node = node
    }
}
