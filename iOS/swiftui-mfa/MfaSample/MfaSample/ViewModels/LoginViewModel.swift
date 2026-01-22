//
//  LoginViewModel.swift
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

/// ViewModel for Journey-based login flow.
@MainActor
class LoginViewModel: ObservableObject {
    // MARK: - Dependencies
    private let journeyManager = JourneyManager.shared

    // MARK: - Published State
    @Published var currentNode: Node?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldDismiss = false

    // MARK: - Callback Values
    /// Dictionary to store callback values by callback type and index.
    @Published var callbackValues: [String: String] = [:]

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init() {
        setupObservers()
    }

    // MARK: - Setup
    private func setupObservers() {
        // Observe journey manager state
        journeyManager.$currentNode
            .assign(to: &$currentNode)

        journeyManager.$isLoading
            .assign(to: &$isLoading)

        journeyManager.$errorMessage
            .assign(to: &$errorMessage)

        journeyManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.handleAuthenticationSuccess()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Journey Actions
    /// Starts the login journey.
    func startLogin() async {
        do {
            try await journeyManager.startJourney(journeyName: "Login")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Submits the current node with callback responses.
    func submitNode() async {
        // Update callback values before submitting
        updateCallbacksWithValues()

        do {
            try await journeyManager.submitNode()
            // Clear callback values after successful submission
            callbackValues.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Callback Handling
    /// Updates callbacks with user-provided values.
    private func updateCallbacksWithValues() {
        guard let node = currentNode as? ContinueNode else { return }

        for (index, callback) in node.callbacks.enumerated() {
            let key = "\(type(of: callback))_\(index)"

            if let nameCallback = callback as? NameCallback,
               let value = callbackValues[key] {
                nameCallback.name = value
            } else if let passwordCallback = callback as? PasswordCallback,
                      let value = callbackValues[key] {
                passwordCallback.password = value
            } else if let textInputCallback = callback as? TextInputCallback,
                      let value = callbackValues[key] {
                textInputCallback.text = value
            } else if let choiceCallback = callback as? ChoiceCallback,
                      let value = callbackValues[key],
                      let index = Int(value) {
                choiceCallback.selectedIndex = index
            }
        }
    }

    /// Gets the callback value key for a given callback.
    func getCallbackKey(for callback: AbstractCallback, at index: Int) -> String {
        return "\(type(of: callback))_\(index)"
    }

    // MARK: - Authentication Success
    private func handleAuthenticationSuccess() {
        // Dismiss after short delay
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
            shouldDismiss = true
        }
    }

    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Cleanup
    func cleanup() {
        journeyManager.reset()
        callbackValues.removeAll()
    }
}
