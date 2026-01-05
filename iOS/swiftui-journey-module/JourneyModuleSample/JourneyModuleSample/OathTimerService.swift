//
//  OathTimerService.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import PingOath
import PingLogger
import Combine

/// A shared service that manages OATH code generation and UI updates efficiently.
/// Uses a dual-timer architecture:
/// - Smart code generation timer: Only regenerates codes when they expire
/// - UI update timer: Updates every second for smooth progress bars
@MainActor
class OathTimerService: ObservableObject {
    // MARK: - Published Properties
    
    /// Map of credential IDs to generated code info
    @Published var generatedCodes: [String: OathCodeInfo] = [:]
    
    /// Current time in milliseconds for UI updates (triggers recomposition)
    @Published var currentTimeMillis: Int64 = 0
    
    // MARK: - Private Properties
    
    private let client: OathClient
    private var codeGenerationTimer: Timer?  // For actual code generation
    private var uiUpdateTimer: Timer?        // For smooth progress updates
    private var credentials: [OathCredential] = []
    private let logger = LogManager.logger
    
    // MARK: - Initialization
    
    init(client: OathClient) {
        self.client = client
        startUIUpdateTimer()  // Always runs at 1Hz for smooth progress
        logger.i("OathTimerService initialized")
    }
    
    // MARK: - Core Methods
    
    /// Start tracking credentials and generating codes
    /// - Parameter credentials: The list of OATH credentials to track
    func startTracking(credentials: [OathCredential]) async {
        logger.i("Starting tracking for \(credentials.count) credentials")
        self.credentials = credentials
        
        // Generate initial codes for all credentials immediately
        for credential in credentials {
            await generateCode(for: credential.id)
        }
        
        // Start intelligent timer for TOTP code regeneration
        scheduleNextCodeGeneration()
    }
    
    /// Generate code for a specific credential (HOTP or manual TOTP refresh)
    /// - Parameter credentialId: The ID of the credential
    func generateCode(for credentialId: String) async {
        // Check if credential is locked
        if let credential = credentials.first(where: { $0.id == credentialId }), credential.isLocked {
            logger.i("Skipping code generation for locked credential: \(credentialId)")
            // Remove any existing code for locked credentials
            generatedCodes.removeValue(forKey: credentialId)
            return
        }
        
        do {
            let codeInfo = try await client.generateCodeWithValidity(credentialId)
            generatedCodes[credentialId] = codeInfo
            logger.i("Generated code for credential: \(credentialId)")
        } catch {
            logger.e("Failed to generate code for \(credentialId): \(error)", error: error)
            // Store error state - will display "ERROR" until next generation
            // Note: Creating a mock OathCodeInfo since we can't initialize it directly
            // The view will display "------" for missing codes
        }
    }
    
    /// Stop tracking credentials and clean up timers
    func stopTracking() {
        logger.i("Stopping credential tracking")
        codeGenerationTimer?.invalidate()
        codeGenerationTimer = nil
        generatedCodes.removeAll()
        credentials.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Intelligent scheduling based on Android pattern
    /// Calculates the minimum time until next code expiration across all TOTP credentials
    private func scheduleNextCodeGeneration() {
        codeGenerationTimer?.invalidate()
        
        let totpCredentials = credentials.filter { $0.oathType == .totp }
        guard !totpCredentials.isEmpty else {
            logger.i("No TOTP credentials to schedule")
            return
        }
        
        // Calculate minimum time until next code expiration (Android pattern)
        let now = Date().timeIntervalSince1970
        let minRemaining = totpCredentials.compactMap { credential -> TimeInterval? in
            let period = TimeInterval(credential.period)
            let timeIntoCurrentPeriod = now.truncatingRemainder(dividingBy: period)
            let remainingTime = period - timeIntoCurrentPeriod
            return remainingTime
        }.min() ?? 1.0
        
        // Schedule next generation with 1 second minimum to avoid rapid firing
        let delay = max(1.0, minRemaining)
        logger.i("Scheduling next code generation in \(delay) seconds")
        
        codeGenerationTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.regenerateTotpCodes()
            }
        }
    }
    
    /// Regenerate all TOTP codes and reschedule
    private func regenerateTotpCodes() async {
        logger.i("Regenerating TOTP codes for \(credentials.filter { $0.oathType == .totp }.count) credentials")
        
        for credential in credentials where credential.oathType == .totp {
            await generateCode(for: credential.id)
        }
        
        // Schedule the next regeneration cycle
        scheduleNextCodeGeneration()
    }
    
    /// Update UI timer (1Hz for smooth progress bars)
    private func startUIUpdateTimer() {
        uiUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentTimeMillis = Int64(Date().timeIntervalSince1970 * 1000)
            }
        }
    }
}
