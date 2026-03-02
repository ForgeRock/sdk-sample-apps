//
//  ManualEntryViewModel.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine

/// ViewModel for manual OATH credential entry.
@MainActor
class ManualEntryViewModel: ObservableObject {
    // MARK: - Dependencies
    private let oathManager = OathManager.shared

    // MARK: - Published Form Fields
    @Published var issuer = ""
    @Published var accountName = ""
    @Published var secretKey = ""
    @Published var oathType: OathType = .totp
    @Published var algorithm: OathAlgorithm = .sha1
    @Published var digits = 6
    @Published var period = 30  // For TOTP
    @Published var counter = 0  // For HOTP

    // MARK: - Published State
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var shouldDismiss = false

    // MARK: - Enums for Form Options
    enum OathType: String, CaseIterable, Identifiable {
        case totp = "TOTP"
        case hotp = "HOTP"

        var id: String { rawValue }
    }

    enum OathAlgorithm: String, CaseIterable, Identifiable {
        case sha1 = "SHA1"
        case sha256 = "SHA256"
        case sha512 = "SHA512"

        var id: String { rawValue }
    }

    // MARK: - Validation
    var isFormValid: Bool {
        !accountName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !secretKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        isSecretKeyValid
    }

    private var isSecretKeyValid: Bool {
        let cleaned = secretKey.trimmingCharacters(in: .whitespaces).uppercased()
        // Base32 characters only (A-Z, 2-7)
        let base32Charset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        return cleaned.unicodeScalars.allSatisfy { base32Charset.contains($0) }
    }

    // MARK: - Registration
    func registerCredential() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields with valid values"
            return
        }

        isProcessing = true
        errorMessage = nil

        do {
            // Construct otpauth:// URI
            let uri = constructOathUri()

            // Register via OathManager
            _ = try await oathManager.addCredentialFromUri(uri)

            isProcessing = false

            // Dismiss after short delay
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            shouldDismiss = true

        } catch {
            errorMessage = "Failed to register credential: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    // MARK: - URI Construction
    private func constructOathUri() -> String {
        var components = URLComponents()
        components.scheme = "otpauth"
        components.host = oathType.rawValue.lowercased()

        // Construct label (issuer:accountName or just accountName)
        let cleanedIssuer = issuer.trimmingCharacters(in: .whitespaces)
        let cleanedAccountName = accountName.trimmingCharacters(in: .whitespaces)

        let label: String
        if !cleanedIssuer.isEmpty {
            label = "\(cleanedIssuer):\(cleanedAccountName)"
        } else {
            label = cleanedAccountName
        }
        components.path = "/\(label)"

        // Clean and uppercase secret key
        let cleanedSecret = secretKey.trimmingCharacters(in: .whitespaces).uppercased()

        // Add query parameters
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "secret", value: cleanedSecret),
            URLQueryItem(name: "algorithm", value: algorithm.rawValue),
            URLQueryItem(name: "digits", value: String(digits))
        ]

        if !cleanedIssuer.isEmpty {
            queryItems.append(URLQueryItem(name: "issuer", value: cleanedIssuer))
        }

        if oathType == .totp {
            queryItems.append(URLQueryItem(name: "period", value: String(period)))
        } else {
            queryItems.append(URLQueryItem(name: "counter", value: String(counter)))
        }

        components.queryItems = queryItems

        return components.url?.absoluteString ?? ""
    }

    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }

    func formatSecretKey() {
        // Auto-format: remove spaces, convert to uppercase
        let formatted = secretKey.replacingOccurrences(of: " ", with: "").uppercased()
        // Only update if changed to avoid re-render loop with .onChange
        if formatted != secretKey {
            secretKey = formatted
        }
    }
}
