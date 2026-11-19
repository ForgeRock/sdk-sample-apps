//
//  RarJson.swift
//  OidcExample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOidc

/// Parses a user-entered `authorization_details` JSON array (RFC 9396 §2) into the typed values the SDK accepts.
///
/// The text goes through `JSONSerialization` and `AuthorizationDetail(anyValue:)` rather than `JSONDecoder`:
/// the bridge classifies JSON booleans correctly on every OS version and reports which part of an entry is
/// malformed, where a `DecodingError` does not read well in the UI.
///
/// Declared `nonisolated` so it can be called from any context.
nonisolated enum RarJson {
    /// A problem with the entered text, phrased for display next to the editor.
    nonisolated struct DecodeError: LocalizedError, Sendable {
        /// The readable description of the problem.
        let message: String

        var errorDescription: String? { message }
    }

    /// Parses `text` as a JSON array of `authorization_details` objects.
    ///
    /// Fails when the text is not valid JSON, is not an array, is an empty array, or contains an entry that is
    /// not an object with a non-empty string `type`.
    /// - Parameter text: The JSON text to parse.
    /// - Returns: The parsed details, or a `DecodeError` describing the first problem found.
    static func decode(_ text: String) -> Result<[AuthorizationDetail], DecodeError> {
        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: Data(text.utf8), options: [.fragmentsAllowed])
        } catch {
            return .failure(DecodeError(message: "Invalid JSON: \(syntaxMessage(for: error))"))
        }

        guard let entries = json as? [Any] else {
            return .failure(DecodeError(message: "The top-level value must be a JSON array of authorization_details objects."))
        }
        guard !entries.isEmpty else {
            return .failure(DecodeError(message: "At least one authorization_details object is required."))
        }

        var details: [AuthorizationDetail] = []
        details.reserveCapacity(entries.count)
        for entry in entries {
            do {
                let detail = try AuthorizationDetail(anyValue: entry)
                guard !detail.type.isEmpty else {
                    return .failure(DecodeError(message: "authorization_details entries require a non-empty 'type' field."))
                }
                details.append(detail)
            } catch let error as OidcError {
                return .failure(DecodeError(message: error.errorMessage))
            } catch {
                return .failure(DecodeError(message: error.localizedDescription))
            }
        }
        return .success(details)
    }

    // MARK: - Private

    /// The parser's own description of where the text stopped being valid JSON.
    private static func syntaxMessage(for error: Error) -> String {
        (error as NSError).userInfo[NSDebugDescriptionErrorKey] as? String ?? error.localizedDescription
    }
}

/// Ready-made `authorization_details` payloads offered as starting points in the editor.
///
/// Declared `nonisolated` so it can be used from any context.
nonisolated enum RarPreset: String, CaseIterable, Identifiable, Sendable {
    /// A `payment_initiation` request using the RFC 9396 example payload.
    case paymentInitiation = "payment_initiation"
    /// An `account_information` request for account listing and balances.
    case accountInformation = "account_information"
    /// A single entry with an empty `type` for the user to fill in.
    case custom = "Custom"

    var id: String { rawValue }

    /// The JSON text for this preset.
    var json: String {
        switch self {
        case .paymentInitiation:
            return """
            [
              {
                "type": "payment_initiation",
                "locations": ["https://example.com/payments"],
                "instructedAmount": {"currency": "EUR", "amount": "123.50"},
                "creditorName": "Merchant A",
                "creditorAccount": {"iban": "DE02100100109307118603"},
                "remittanceInformationUnstructured": "Ref Number Merchant"
              }
            ]
            """
        case .accountInformation:
            return """
            [
              {
                "type": "account_information",
                "actions": ["list_accounts", "read_balances"],
                "locations": ["https://example.com/accounts"],
                "datatypes": ["balances"]
              }
            ]
            """
        case .custom:
            return """
            [
              {
                "type": ""
              }
            ]
            """
        }
    }
}
