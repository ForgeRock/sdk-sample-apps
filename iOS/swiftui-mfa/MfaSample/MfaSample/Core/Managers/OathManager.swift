//
//  OathManager.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOath
import Combine

/// Manager class for handling all OATH credential operations.
/// Encapsulates OATH-specific business logic and state management.
@MainActor
class OathManager: ObservableObject {
    static let shared = OathManager()

    private var oathClient: OathClient?

    @Published var oathCredentials: [OathCredential] = []
    @Published var isLoadingCredentials: Bool = false
    @Published var generatedCodes: [String: OathCodeInfo] = [:]
    @Published var lastAddedCredential: OathCredential?

    private init() {}

    /// Sets the OATH client instance.
    /// - Parameter client: The OathClient to use.
    func setClient(_ client: OathClient) {
        self.oathClient = client
    }

    /// Loads all OATH credentials from the SDK.
    /// - Returns: Array of OATH credentials.
    func loadCredentials() async throws -> [OathCredential] {
        guard let client = oathClient else {
            // Client not initialized yet - return empty array without error
            self.oathCredentials = []
            return []
        }

        isLoadingCredentials = true
        defer { isLoadingCredentials = false }

        do {
            let credentials = try await Task.detached(priority: .userInitiated) {
                try await client.getCredentials()
            }.value
            self.oathCredentials = credentials
            return credentials
        } catch {
            throw AppError.oathError("Failed to load credentials: \(error.localizedDescription)")
        }
    }

    /// Adds an OATH credential from a URI.
    /// - Parameter uri: The otpauth:// URI string.
    /// - Returns: The created OathCredential.
    func addCredentialFromUri(_ uri: String) async throws -> OathCredential {
        guard let client = oathClient else {
            throw AppError.oathError("OATH client not initialized")
        }

        do {
            let credential = try await Task.detached(priority: .userInitiated) {
                try await client.addCredentialFromUri(uri)
            }.value
            self.lastAddedCredential = credential
            // Reload credentials to refresh the list
            _ = try await loadCredentials()
            return credential
        } catch {
            throw AppError.oathError("Failed to add credential: \(error.localizedDescription)")
        }
    }

    /// Removes an OATH credential from the SDK.
    /// - Parameter credentialId: The ID of the credential to remove.
    /// - Returns: True if the credential was removed.
    func removeCredential(_ credentialId: String) async throws -> Bool {
        guard let client = oathClient else {
            throw AppError.oathError("OATH client not initialized")
        }

        do {
            let removed = try await Task.detached(priority: .userInitiated) {
                try await client.deleteCredential(credentialId)
            }.value
            if removed {
                // Reload credentials to refresh the list
                _ = try await loadCredentials()
            }
            return removed
        } catch {
            throw AppError.oathError("Failed to remove credential: \(error.localizedDescription)")
        }
    }

    /// Updates an OATH credential in the SDK.
    /// - Parameter credential: The credential to update.
    /// - Returns: The updated credential.
    func updateCredential(_ credential: OathCredential) async throws -> OathCredential {
        guard let client = oathClient else {
            throw AppError.oathError("OATH client not initialized")
        }

        do {
            let updated = try await Task.detached(priority: .userInitiated) {
                try await client.saveCredential(credential)
            }.value
            // Reload credentials to refresh the list
            _ = try await loadCredentials()
            return updated
        } catch {
            throw AppError.oathError("Failed to update credential: \(error.localizedDescription)")
        }
    }

    /// Updates the display names on a batch of OATH credentials.
    /// - Parameters:
    ///   - credentials: The credentials to update.
    ///   - issuer: The new display issuer string.
    ///   - accountName: The new display account name string.
    func updateDisplayNames(for credentials: [OathCredential], issuer: String, accountName: String) async throws {
        for credential in credentials {
            var updated = credential
            updated.displayIssuer = issuer
            updated.displayAccountName = accountName
            _ = try await updateCredential(updated)
        }
    }

    /// Generates a code for a credential.
    /// - Parameter credentialId: The ID of the credential.
    /// - Returns: The generated OathCodeInfo.
    func generateCode(for credentialId: String) async throws -> OathCodeInfo {
        guard let client = oathClient else {
            throw AppError.oathError("OATH client not initialized")
        }

        do {
            let codeInfo = try await Task.detached(priority: .userInitiated) {
                try await client.generateCodeWithValidity(credentialId)
            }.value
            self.generatedCodes[credentialId] = codeInfo
            return codeInfo
        } catch {
            throw AppError.oathError("Failed to generate code: \(error.localizedDescription)")
        }
    }

    /// Clears the last added OATH credential.
    func clearLastAddedCredential() {
        lastAddedCredential = nil
    }

    /// Closes the OATH client and releases resources.
    func close() async {
        do {
            try await oathClient?.close()
        } catch {
            print("Error closing OATH client: \(error.localizedDescription)")
        }
    }
}
