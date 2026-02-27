//
//  AppConfiguration.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOath
import PingPush
import Combine

/// Centralized app configuration and SDK initialization.
@MainActor
class AppConfiguration: ObservableObject {
    static let shared = AppConfiguration()

    @Published var isInitialized = false

    private var initializationTask: Task<Void, Never>?

    private init() {}

    /// Initializes all SDK clients. Safe to call multiple times — initialization runs only once.
    /// If initialization previously failed, calling this again will retry.
    func initialize() async {
        if initializationTask == nil {
            initializationTask = Task {
                do {
                    // Initialize both clients in parallel off the main actor
                    // (SDK uses synchronous keychain I/O internally)
                    async let oathResult = Task.detached(priority: .userInitiated) {
                        try await OathClient.createClient()
                    }.value
                    async let pushResult = Task.detached(priority: .userInitiated) {
                        try await PushClient.createClient()
                    }.value

                    let (oathClient, pushClient) = try await (oathResult, pushResult)
                    OathManager.shared.setClient(oathClient)
                    PushManager.shared.setClient(pushClient)

                    isInitialized = true

                    DiagnosticLogger.shared.info("SDK clients initialized successfully", category: "AppConfiguration")
                } catch {
                    // Reset so initialization can be retried on next call
                    initializationTask = nil
                    DiagnosticLogger.shared.error("Failed to initialize SDK clients: \(error.localizedDescription)", category: "AppConfiguration")
                }
            }
        }
        await initializationTask?.value
    }
}
