/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingBrowser
import PingDavinci
import PingOidc
import PingStorage

/// Errors the bridge itself throws.
enum DaVinciHostApiError: Error, CustomStringConvertible {
    case daVinciNotFound(String)
    case stateError(String)
    case argument(String)
    case unsupported(String)

    /// Plain message text, matching Kotlin's `IllegalStateException.message`/etc. shape rather
    /// than Swift's default enum-case reflection (e.g. `stateError("...")`).
    var description: String {
        switch self {
        case .daVinciNotFound(let message),
             .stateError(let message),
             .argument(let message),
             .unsupported(let message):
            return message
        }
    }
}

/// Classifies a native failure into a Pigeon `PigeonError` carrying a stable per-operation
/// `code` plus a small `type` classification in `details`, surfaced to Dart as
/// `PingException.type`. Same contract as `ping_journey`'s `JourneyErrorMapper`.
///
/// `PigeonError` is used rather than Flutter's `FlutterError`, which does not conform to Swift's
/// `Error` and so cannot satisfy `Result<T, Error>`.
enum DaVinciErrorMapper {
    /// Wraps any caught `Error` as a classified `PigeonError`, unless it already is one.
    static func from(_ code: String, _ error: Error) -> PigeonError {
        if let pigeonError = error as? PigeonError { return pigeonError }
        if let oidcError = error as? OidcError { return from(code, oidcError) }
        let type: String
        switch error {
        case DaVinciHostApiError.daVinciNotFound, DaVinciHostApiError.stateError:
            type = "state"
        case DaVinciHostApiError.argument:
            type = "argument"
        case DaVinciHostApiError.unsupported:
            type = "unsupported"
        case is PingDavinci.ApiError:
            type = "exchange"
        case BrowserError.externalUserAgentCancelled:
            type = "cancelled"
        case is BrowserError:
            type = "browser"
        case is KeychainError, is EncryptorError:
            type = "storage"
        case is PollingError:
            type = "polling"
        case is SerializationError:
            type = "serialization"
        default:
            type = "unknown"
        }
        return PigeonError(code: code, message: plainErrorMessage(for: error), details: type)
    }

    /// Classifies an `OidcError` value (not caught via `throws` — returned via `Result.failure`).
    static func from(_ code: String, _ error: OidcError) -> PigeonError {
        let type: String
        switch error {
        case .authorizeError: type = "auth"
        case .networkError: type = "network"
        case .apiError: type = "exchange"
        // Neither a usable `discoveryEndpoint` nor `openId`: a caller error.
        case .configurationError: type = "argument"
        case .unknown: type = "unknown"
        }
        return PigeonError(code: code, message: error.errorMessage, details: type)
    }
}

/// Plain message text for an arbitrary caught `Error`, preferring `LocalizedError.errorDescription`
/// and `CustomStringConvertible.description` over `localizedDescription`, which for a plain custom
/// `Error` falls back to a generic bridged `NSError` description.
func plainErrorMessage(for error: Error) -> String {
    if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
        return description
    }
    if let describable = error as? CustomStringConvertible {
        return describable.description
    }
    return error.localizedDescription
}
