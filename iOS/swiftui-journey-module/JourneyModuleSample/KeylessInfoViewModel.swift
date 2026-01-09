//
//  KeylessInfoViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import KeylessSDK
import PingLogger
import Combine

/// A view model responsible for fetching and managing Keyless SDK information.
/// - Provides published properties for device identifier and user ID from Keyless SDK.
@MainActor
class KeylessInfoViewModel: ObservableObject {
    /// Published property to hold the Keyless device identifier.
    @Published var deviceIdentifier: String = "Not found"
    
    /// Published property to hold the Keyless user ID.
    @Published var userID: String = "Not found"
    
    /// Initializes the `KeylessInfoViewModel` and collects Keyless information.
    /// - The data is fetched during initialization.
    init() {
        collectKeylessInfo()
    }
    
    /// Collects Keyless SDK information
    /// - Retrieves the device identifier and user ID from Keyless SDK.
    /// - Updates the published properties with the collected info.
    /// - Logs success and error messages using `PingLogger`.
    func collectKeylessInfo() {
        // Get Device Public Signing Key
        let deviceKeyResult = Keyless.getDevicePublicSigningKey()
        switch deviceKeyResult {
        case .success(let identifier):
            deviceIdentifier = identifier
            LogManager.standard.i("Keyless Device Public Signing Key: \(identifier)")
        case .failure(let error):
            deviceIdentifier = "Not found"
            LogManager.standard.w("Keyless Device Public Signing Key not available", error: error)
        }
        
        // Get User ID
        let userIdResult = Keyless.getUserId()
        switch userIdResult {
        case .success(let userId):
            userID = userId
            LogManager.standard.i("Keyless User ID: \(userId)")
        case .failure(let error):
            userID = "Not found"
            LogManager.standard.w("Keyless User ID not available", error: error)
        }
    }
}
