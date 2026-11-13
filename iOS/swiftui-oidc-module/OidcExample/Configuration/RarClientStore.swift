//
//  RarClientStore.swift
//  OidcExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOrchestrate
import PingOidc
import PingStorage

/// The client settings that are fixed when a Rich Authorization Requests (RFC 9396) client is built.
///
/// Declared `nonisolated` so the value can be read from the `@Sendable` closure that configures the client.
nonisolated struct RarClientOptions: Equatable, Sendable {
    /// Whether the authorization parameters are pushed to the server first (RFC 9126).
    var par: Bool = false
    /// `authorization_details` sent with every authorization request made by the client.
    var authorizationDetails: [AuthorizationDetail]?
}

/// Owns the OIDC Web client used for Rich Authorization Requests (RFC 9396).
///
/// `par` and the config-level `authorizationDetails` are fixed when a client is built, so changing
/// them builds a new client; `apply(_:)` keeps the current client while the options are unchanged.
///
/// The client stores its token in its own Keychain account (`storageAccount`), separate from the
/// standard `oidcLogin` client. Starting an authorization revokes and clears the token held in the
/// storage of the client that starts it, so a shared account would let a RAR authorization revoke
/// the standard token. A rebuilt client reads the same persisted token slot, so the token survives
/// both a rebuild and an app relaunch.
@MainActor
final class RarClientStore {
    /// The store shared by the RAR screens.
    static let shared = RarClientStore()

    /// The Keychain account that holds the RAR token.
    ///
    /// Declared `nonisolated` so it can be read from the `@Sendable` closure that configures the client.
    nonisolated static let storageAccount = "ACCESS_TOKEN_STORAGE_RAR"

    /// The OAuth 2.0 client the RAR client authenticates as.
    ///
    /// Consent handling is a per-client setting on the authorization server, and the two flows
    /// need different settings: Implied Consent on a client rejects `authorization_details` with
    /// `invalid_request`, while a standard login usually wants no consent prompt. Point this at a
    /// second client that has Implied Consent off, the requested Authorization Detail Type(s)
    /// listed, and remote consent with the agent enabled.
    nonisolated static let clientId = <#"RAR Client ID"#>

    /// The client for the current `options`.
    private(set) var client: OidcWebClient
    /// The options the current `client` was built with.
    private(set) var options: RarClientOptions

    private init() {
        let options = RarClientOptions()
        self.options = options
        self.client = RarClientStore.makeClient(options: options)
    }

    /// Makes `options` current, building a new client only when they differ from the current ones.
    /// - Parameter options: The options the next authorization should use.
    func apply(_ options: RarClientOptions) {
        guard options != self.options else { return }
        client = RarClientStore.makeClient(options: options)
        self.options = options
    }

    // MARK: - Private

    /// Builds a client that authenticates as the RAR client, keeps its token in `storageAccount`,
    /// and applies `options`.
    ///
    /// Takes `options` by value so the configuring closure captures no main-actor state.
    private nonisolated static func makeClient(options: RarClientOptions) -> OidcWebClient {
        makeOidcWebClient { oidcValue in
            oidcValue.clientId = RarClientStore.clientId
            oidcValue.storage = KeychainStorage<Token>(
                account: RarClientStore.storageAccount,
                encryptor: SecuredKeyEncryptor() ?? NoEncryptor(),
                cacheStrategy: .NO_CACHE
            )
            oidcValue.par = options.par
            oidcValue.authorizationDetails = options.authorizationDetails
        }
    }
}
