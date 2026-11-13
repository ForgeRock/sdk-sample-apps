//
//  OidcError+Display.swift
//  OidcExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingBrowser
import PingOidc

extension OidcError {
    /// A message for showing the error to the user.
    ///
    /// `localizedDescription` of an authorization error repeats its prefix ("Authorization error: Authorization
    /// failed: ..."). This maps the outcomes a Rich Authorization Requests (RFC 9396) flow commonly ends in to
    /// plain language, with the server's `error_description` on its own line when it sent one:
    /// - `access_denied`: the user declined consent.
    /// - `invalid_authorization_details`: the server rejected the `authorization_details`, so the types allowed on
    ///   the OAuth client need checking.
    /// - `invalid_request`: the server rejected the request, as an OAuth client with Implied Consent enabled does
    ///   for `authorization_details`.
    /// - Any other OAuth error: the error code.
    /// - `BrowserError.externalUserAgentCancelled`: the user dismissed the sign-in browser.
    ///
    /// Every other error falls back to `localizedDescription`.
    nonisolated var displayMessage: String {
        guard case .authorizeError(cause: let cause, message: _) = self else {
            return localizedDescription
        }
        if let oauthError = cause as? OAuthAuthorizationError {
            return OidcError.message(for: oauthError)
        }
        if let browserError = cause as? BrowserError, case .externalUserAgentCancelled = browserError {
            return "Sign-in was cancelled before it completed."
        }
        return localizedDescription
    }

    // MARK: - Private

    /// Builds the message for an OAuth error returned on the authorization redirect: a headline, the server
    /// description when present, then any closing note, each on its own line.
    private nonisolated static func message(for error: OAuthAuthorizationError) -> String {
        let headline: String
        var note: String?
        switch error.code {
        case "access_denied":
            headline = "Consent was denied. The user declined the authorization request."
        case "invalid_authorization_details":
            headline = "The server rejected the authorization_details. Check the Authorization Detail Type(s) allowed on the OAuth client."
        case "invalid_request":
            headline = "The server rejected the authorization request."
            note = "A client with Implied Consent enabled rejects authorization_details."
        default:
            headline = "Authorization failed: \(error.code)"
        }

        let description = error.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        let serverDescription = description?.isEmpty == false ? description : nil
        return [headline, serverDescription, note].compactMap { $0 }.joined(separator: "\n")
    }
}
