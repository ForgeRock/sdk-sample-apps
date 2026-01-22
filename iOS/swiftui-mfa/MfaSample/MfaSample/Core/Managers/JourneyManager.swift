//
//  JourneyManager.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Combine
import PingJourney
import PingOrchestrate
import PingJourneyPlugin

/// Manager for Journey-based authentication and MFA registration.
@MainActor
class JourneyManager: ObservableObject {
    // MARK: - Singleton
    static let shared = JourneyManager()

    // MARK: - Dependencies
    private let oathManager = OathManager.shared
    private let pushManager = PushManager.shared

    // MARK: - Published State
    @Published var currentNode: Node?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var userId: String?

    // MARK: - Private Properties
    private var journey: Journey

    // MARK: - Initialization
    private init() {
        // Create Journey instance with default configuration
        journey = Journey.createJourney { config in
            // TODO: Configure with actual server details
            config.serverUrl = "https://your-server.example.com/am"
            config.realm = "alpha"
            config.cookie = "iPlanetDirectoryPro"
        }
    }

    // MARK: - Journey Flow
    /// Starts a new Journey authentication flow.
    func startJourney(journeyName: String = "Login") async throws {
        isLoading = true
        errorMessage = nil

        let node = await journey.start(journeyName) { options in
            options.forceAuth = false
            options.noSession = false
        }

        await processNode(node)
        isLoading = false
    }

    /// Submits the current node with callback responses.
    func submitNode() async throws {
        guard let currentNode = currentNode as? ContinueNode else {
            throw JourneyError.noActiveNode
        }

        isLoading = true
        errorMessage = nil

        let nextNode = await currentNode.next()
        await processNode(nextNode)
        isLoading = false
    }

    // MARK: - Node Processing
    /// Processes a node and handles MFA registration.
    private func processNode(_ node: Node) async {
        if node is SuccessNode {
            // Authentication successful
            isAuthenticated = true

            // Note: Token retrieval would be done through the OidcModule
            // For now, we'll mark as authenticated
            currentNode = nil
        } else {
            // Continue with next node
            currentNode = node

            // Check for MFA registration callbacks
            await detectAndHandleMfaRegistration(in: node)
        }
    }

    /// Detects and handles HiddenValueCallback for MFA device registration.
    private func detectAndHandleMfaRegistration(in node: Node) async {
        guard let continueNode = node as? ContinueNode else { return }

        for callback in continueNode.callbacks {
            if let hiddenCallback = callback as? HiddenValueCallback,
               hiddenCallback.valueId == "mfaDeviceRegistration",
               !hiddenCallback.value.isEmpty {

                // Parse the URI and register the credential
                await registerMfaCredential(uri: hiddenCallback.value)
            }
        }
    }

    /// Registers an MFA credential from the Journey flow.
    private func registerMfaCredential(uri: String) async {
        let parseResult = QRCodeParser.parse(uri)

        switch parseResult {
        case .oath(let oathUri):
            do {
                _ = try await oathManager.addCredentialFromUri(oathUri)
            } catch {
                print("Failed to register OATH credential from Journey: \(error)")
            }

        case .push(let pushUri):
            do {
                _ = try await pushManager.addCredentialFromUri(pushUri)
            } catch {
                print("Failed to register Push credential from Journey: \(error)")
            }

        case .mfa(let mfaUri):
            // Register both - let the SDK handle the mfauth:// format
            do {
                _ = try await oathManager.addCredentialFromUri(mfaUri)
            } catch {
                print("Failed to register OATH credential from Journey mfauth://: \(error)")
            }
            
            do {
                _ = try await pushManager.addCredentialFromUri(mfaUri)
            } catch {
                print("Failed to register Push credential from Journey mfauth://: \(error)")
            }

        case .invalid(let message):
            print("Invalid MFA registration URI from Journey: \(message)")
        }
    }

    /// Associates a userId with all existing credentials.
    private func associateUserIdWithCredentials(_ userId: String) async {
        // Note: Currently the SDK doesn't support associating userId with credentials after creation
        // This would be implemented when SDK adds support for this feature
        print("Associating userId \(userId) with credentials")
    }

    // MARK: - Helper Methods
    /// Extracts userId (sub claim) from JWT access token.
    private func extractUserIdFromToken(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }

        // Decode payload (second part)
        let payload = String(parts[1])
        guard let data = Data(base64Encoded: payload.base64PaddingAdded()) else {
            return nil
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let sub = json["sub"] as? String {
                return sub
            }
        } catch {
            print("Failed to decode JWT: \(error)")
        }

        return nil
    }

    /// Resets the Journey state.
    func reset() {
        currentNode = nil
        isAuthenticated = false
        userId = nil
        errorMessage = nil
    }
}

// MARK: - Journey Errors

enum JourneyError: LocalizedError {
    case noActiveNode
    case authenticationFailed

    var errorDescription: String? {
        switch self {
        case .noActiveNode:
            return "No active authentication node"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}

// MARK: - String Extension for Base64

private extension String {
    func base64PaddingAdded() -> String {
        let remainder = count % 4
        if remainder > 0 {
            return padding(toLength: count + 4 - remainder, withPad: "=", startingAt: 0)
        }
        return self
    }
}
