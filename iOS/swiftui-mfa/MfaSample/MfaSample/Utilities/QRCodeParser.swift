//
//  QRCodeParser.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Result of parsing a QR code URI.
enum QRCodeParseResult {
    case oath(String)           // Contains the full URI string
    case push(String)           // Contains the full URI string
    case mfa(String)            // Contains the full URI string (SDK will parse both components)
    case invalid(String)
}

/// Utility for detecting QR code URI types for MFA registration.
/// The actual parsing is handled by the SDK modules (PingOath, PingPush).
struct QRCodeParser {

    /// Detects the type of QR code URI.
    static func parse(_ qrCode: String) -> QRCodeParseResult {
        guard let url = URL(string: qrCode),
              let scheme = url.scheme?.lowercased() else {
            return .invalid("Invalid QR code format")
        }

        switch scheme {
        case "otpauth":
            return .oath(qrCode)
        case "pushauth":
            return .push(qrCode)
        case "mfauth":
            return .mfa(qrCode)
        default:
            return .invalid("Unsupported URI scheme: \(scheme)")
        }
    }
}
