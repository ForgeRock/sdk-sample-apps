//
//  AppError.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation

/// Enum representing application-wide errors with localized descriptions.
enum AppError: LocalizedError {
    case oathError(String)
    case pushError(String)
    case journeyError(String)
    case biometricError(String)
    case networkError(String)
    case storageError(String)
    case qrCodeError(String)
    case validationError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .oathError(let message):
            return "OATH Error: \(message)"
        case .pushError(let message):
            return "Push Error: \(message)"
        case .journeyError(let message):
            return "Journey Error: \(message)"
        case .biometricError(let message):
            return "Biometric Error: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .storageError(let message):
            return "Storage Error: \(message)"
        case .qrCodeError(let message):
            return "QR Code Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .unknown(let message):
            return "Error: \(message)"
        }
    }
}
