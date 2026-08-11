/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingOidc

/// Errors the bridge itself throws, before ever reaching a native OIDC call.
enum OidcHostApiError: Error, CustomStringConvertible {
    case argumentError(String)
    case stateError(String)

    /// Plain message text, matching Kotlin's `IllegalArgumentException.message`/etc. shape
    /// rather than Swift's default enum-case reflection (e.g. `argumentError("...")`).
    var description: String {
        switch self {
        case .argumentError(let message), .stateError(let message):
            return message
        }
    }
}

/// Classifies a native failure into a Pigeon `PigeonError` carrying a stable per-operation `code`
/// plus a small `type` classification in `details`, surfaced to Dart as `PingException.type` (see
/// `OidcClient._guard`). Mirrors `ping_journey`'s `JourneyErrorMapper` shape.
enum OidcErrorMapper {
    /// Wraps any caught `Error` as a classified `PigeonError`, unless it already is one.
    ///
    /// `PigeonError` (Pigeon's own `Error`-conforming type, defined in `Messages.g.swift`) is used
    /// here rather than Flutter's `FlutterError` — the latter is an Objective-C bridged class that
    /// does not conform to Swift's `Error` protocol, so it cannot satisfy `Result<T, Error>`.
    static func from(_ code: String, _ error: Error) -> PigeonError {
        if let pigeonError = error as? PigeonError { return pigeonError }
        if let oidcError = error as? OidcError { return from(code, oidcError) }
        let type: String
        switch error {
        case OidcHostApiError.argumentError:
            type = "argument"
        case OidcHostApiError.stateError:
            type = "state"
        default:
            type = "unknown"
        }
        return PigeonError(code: code, message: plainErrorMessage(for: error), details: type)
    }

    /// Classifies an `OidcError` value.
    static func from(_ code: String, _ error: OidcError) -> PigeonError {
        let type: String
        switch error {
        case .authorizeError: type = "auth"
        case .networkError: type = "network"
        case .apiError: type = "exchange"
        case .unknown: type = "unknown"
        }
        return PigeonError(code: code, message: error.errorMessage, details: type)
    }

    /// A stub error for a method not yet implemented in this phase.
    static func notImplemented(_ code: String) -> PigeonError {
        PigeonError(code: code, message: "Not implemented until a later phase", details: "not_implemented")
    }
}

/// Plain message text for an arbitrary caught `Error`, preferring `LocalizedError.errorDescription`
/// over `String(describing:)` — which for a Swift enum with associated values dumps the
/// case/argument reflection rather than clean text. Ported from `ping_journey`'s
/// `JourneyErrorMapper.swift`.
func plainErrorMessage(for error: Error) -> String {
    if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
        return description
    }
    if let describable = error as? CustomStringConvertible {
        return describable.description
    }
    return error.localizedDescription
}
