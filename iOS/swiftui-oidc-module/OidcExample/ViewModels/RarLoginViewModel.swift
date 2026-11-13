//
//  RarLoginViewModel.swift
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
import PingLogger
import Combine

/// A view model that manages the OIDC login flow with RFC 9396 `authorization_details`.
/// - Responsible for:
///   - Validating the edited `authorization_details` JSON
///   - Applying the PAR flag and the delivery choice to the RAR client before a login
///   - Running the authorization with the dedicated RAR client
///   - Managing authentication state (success/failure) and the loading state
@MainActor
class RarLoginViewModel: ObservableObject {
    /// How the `authorization_details` reach the authorization server for a login.
    /// - `perTransaction`: sent for the current login only, through `OidcOptions.authorizationDetails`.
    /// - `clientConfig`: fixed when the client is built, through `OidcClientConfig.authorizationDetails`.
    /// A per-transaction value takes precedence over a config-level one.
    ///
    /// Declared `nonisolated` so the value can be used from any context.
    nonisolated enum Delivery: CaseIterable, Hashable, Identifiable {
        /// The details travel with the single authorization request.
        case perTransaction
        /// The details are set on the client configuration and sent with every authorization.
        case clientConfig

        var id: Self { self }

        /// The label shown in the delivery picker, the status card, and the log line.
        var displayName: String {
            switch self {
            case .perTransaction: return "Per transaction"
            case .clientConfig: return "Client config"
            }
        }
    }

    /// The preset currently selected as the editor's starting point.
    @Published var preset: RarPreset = .paymentInitiation
    /// The `authorization_details` JSON the user is editing.
    @Published var jsonText: String = RarPreset.paymentInitiation.json
    /// Live validation message for the editor text (`nil` when the text is valid or empty).
    @Published var validationError: String?
    /// Whether the authorization parameters are pushed to the server first (RFC 9126).
    /// Applied to the client when a login starts.
    @Published var parEnabled: Bool = false
    /// Whether the edited details are sent per transaction or fixed on the client configuration.
    @Published var delivery: Delivery = .perTransaction
    /// Published property that holds the current authentication state.
    @Published var state: Result<User, OidcError>?
    /// Published property to track whether the view is currently loading.
    @Published var isLoading: Bool = false

    /// Loads the selected preset's JSON into the editor and revalidates it.
    /// - Parameter preset: The preset the user picked.
    func selectPreset(_ preset: RarPreset) {
        self.preset = preset
        jsonText = preset.json
        _ = validate()
    }

    /// Validates the editor text and records the outcome in `validationError` for display.
    /// - Returns: The decoded details, or `nil` when the text is empty or invalid.
    /// - Note: Event-handler use only, because it publishes; calling it from a view's `body`
    ///   crashes SwiftUI. Use `decodedDetails()` there instead.
    func validate() -> [AuthorizationDetail]? {
        let trimmed = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            validationError = nil
            return nil
        }
        switch RarJson.decode(trimmed) {
        case .success(let details):
            validationError = nil
            return details
        case .failure(let error):
            validationError = error.message
            return nil
        }
    }

    /// Pure validation: decodes the current text without touching published state, so it is safe
    /// to call from a view's `body` (for example to drive the login button's disabled state).
    /// - Returns: The decoded details, or `nil` when the text is empty or invalid.
    func decodedDetails() -> [AuthorizationDetail]? {
        let trimmed = jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if case .success(let details) = RarJson.decode(trimmed) { return details }
        return nil
    }

    /// Starts the OIDC login with the edited `authorization_details`.
    ///
    /// Applies the current PAR flag and delivery choice to `RarClientStore` first, which rebuilds
    /// the client when they changed, then runs the authorization. With client-config delivery the
    /// details are set on the client configuration; with per-transaction delivery they are passed
    /// through the `authorize` configure closure, which captures only the details value so it
    /// stays `@Sendable`.
    func login() async {
        guard let details = validate() else { return }

        isLoading = true
        defer { isLoading = false }

        // Only flags and `type` values are logged, never the payload, tokens, or the editor text.
        LogManager.standard.i(
            "RAR login: PAR \(parEnabled ? "on" : "off"), "
                + "delivery \(delivery.displayName), "
                + "authorization_details types: \(details.map(\.type).joined(separator: ", "))"
        )

        RarClientStore.shared.apply(
            RarClientOptions(
                par: parEnabled,
                authorizationDetails: delivery == .clientConfig ? details : nil
            )
        )
        let perTransaction: [AuthorizationDetail]? = delivery == .perTransaction ? details : nil

        do {
            state = try await RarClientStore.shared.client.authorize { options in
                options.authorizationDetails = perTransaction
            }
        } catch let error as OidcError {
            state = .failure(error)
        } catch {
            state = .failure(.unknown(cause: error))
        }
    }
}
