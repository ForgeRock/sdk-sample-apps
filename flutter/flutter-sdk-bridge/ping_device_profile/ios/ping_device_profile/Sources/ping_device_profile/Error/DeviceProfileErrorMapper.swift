/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import ping_core

/// Classifies a native failure into a Pigeon `PigeonError` carrying a stable per-operation `code`
/// plus a small `type` classification in `details`, surfaced to Dart as `PingException.type` (see
/// the Dart facade). Mirrors the sibling modules' mappers.
///
/// The native SDK's own location failures (`LocationError.authorizationDenied` and friends) are
/// `internal` to `PingDeviceProfile`, so they can't be type-matched here and classify as
/// `unknown`. Android's counterpart is a typed `SecurityException` and classifies as `permission`.
enum DeviceProfileErrorMapper {
    /// Wraps any caught `Error` as a classified `PigeonError`, unless it already is one.
    static func from(_ code: String, _ error: Error) -> PigeonError {
        if let pigeonError = error as? PigeonError { return pigeonError }
        let type: String
        switch error {
        case DeviceProfileHostApiError.argumentError: type = "argument"
        case DeviceProfileHostApiError.stateError: type = "state"
        case ActiveNodeError.noActiveNode, ActiveNodeError.notFound: type = "state"
        case ActiveNodeError.itemNotFound: type = "argument"
        default: type = "unknown"
        }
        return PigeonError(code: code, message: plainErrorMessage(for: error), details: type)
    }
}

/// Errors the bridge itself throws, before ever reaching a native collection.
enum DeviceProfileHostApiError: Error, CustomStringConvertible {
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

/// Plain message text for an arbitrary caught `Error`, preferring `LocalizedError.errorDescription`
/// over `String(describing:)` — which for a Swift enum with associated values dumps the
/// case/argument reflection rather than clean text. Ported from `ping_oidc`'s mapper.
func plainErrorMessage(for error: Error) -> String {
    if let localizedError = error as? LocalizedError, let description = localizedError.errorDescription {
        return description
    }
    if let describable = error as? CustomStringConvertible {
        return describable.description
    }
    return error.localizedDescription
}
