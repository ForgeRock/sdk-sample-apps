/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingJourney
import PingOidc

/// Classifies a native failure into a Pigeon `FlutterError` carrying a stable per-operation
/// `code` plus a small `type` classification in `details`, surfaced to Dart as
/// `PingException.type` (see `JourneyClient._guard`).
///
/// Native `Journey.start()`/`ContinueNode.next()` never throw — failure is always a returned
/// `FailureNode`/`ErrorNode`, already handled by `JourneyNodeMapper` — so this mapper only needs
/// to classify `OidcError` (from `getSession`'s `Result.failure`) and the handful of error types
/// the bridge itself throws (`JourneyHostApiError`).
enum JourneyErrorMapper {
    /// Wraps any caught `Error` as a classified `PigeonError`, unless it already is one.
    ///
    /// `PigeonError` (Pigeon's own `Error`-conforming type, defined in `Messages.g.swift`) is used
    /// here rather than Flutter's `FlutterError` — the latter is an Objective-C bridged class that
    /// does not conform to Swift's `Error` protocol, so it cannot satisfy `Result<T, Error>`.
    /// Pigeon's generated `wrapError` recognizes `PigeonError` and forwards its
    /// `code`/`message`/`details` to Dart identically to `FlutterError`.
    static func from(_ code: String, _ error: Error) -> PigeonError {
        if let pigeonError = error as? PigeonError { return pigeonError }
        if let oidcError = error as? OidcError { return from(code, oidcError) }
        let type: String
        switch error {
        case JourneyHostApiError.journeyNotFound, JourneyHostApiError.stateError:
            type = "state"
        case JourneyHostApiError.unsupported, JourneyHostApiError.callbackApply:
            type = "argument"
        default:
            type = "unknown"
        }
        return PigeonError(code: code, message: String(describing: error), details: type)
    }

    /// Classifies an `OidcError` value (not caught via `throws` — returned via `Result.failure`).
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
}
