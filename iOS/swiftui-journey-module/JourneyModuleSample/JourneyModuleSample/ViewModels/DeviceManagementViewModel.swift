//
//  DeviceManagementViewModel.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingLogger
import PingOrchestrate
import PingStorage
import PingDeviceClient
import PingJourney
import PingOidc
import Combine

/// Enum representing different device types for the UI
enum DeviceType: String, CaseIterable, Identifiable {
    case oath = "Oath"
    case push = "Push"
    case bound = "Bound"
    case profile = "Profile"
    case webAuthn = "WebAuthn"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .oath: return "timer"
        case .push: return "bell.fill"
        case .bound: return "link"
        case .profile: return "person.crop.circle"
        case .webAuthn: return "key.fill"
        }
    }
    
}

/// ViewModel for managing devices
@MainActor
class DeviceManagementViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var oathDevices: [OathDevice] = []
    @Published var pushDevices: [PushDevice] = []
    @Published var boundDevices: [BoundDevice] = []
    @Published var profileDevices: [ProfileDevice] = []
    @Published var webAuthnDevices: [WebAuthnDevice] = []
    
    @Published var isLoading = false
    @Published var isInitializing = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedDeviceType: DeviceType = .oath
    
    // MARK: - Private Properties
    
    private var deviceClient: DeviceClient?
    
    // MARK: - Initialization
    
    /// Initializes the DeviceClient with configuration
    /// - Returns: true if initialization succeeded, false otherwise
    @discardableResult
    func initialize() async -> Bool {
        isInitializing = true
        errorMessage = nil
        
        defer {
            isInitializing = false
        }
        
        // Load configuration
        let config = journey.config as? JourneyConfig
        
        // Validate configuration
        guard let serverUrl = config?.serverUrl, !serverUrl.isEmpty else {
            errorMessage = "Server URL is not configured. Please check settings."
            LogManager.logger.e("DeviceManagement: Missing server URL", error: nil)
            return false
        }
        
        guard let realm = config?.realm, !realm.isEmpty else {
            errorMessage = "Realm is not configured. Please check settings."
            LogManager.logger.e("DeviceManagement: Missing realm", error: nil)
            return false
        }
        
        let cookieName = config?.cookie ?? "iPlanetDirectoryPro"
        
        // Get session token
        guard let sessionToken = await journey.journeyUser()?.session?.value,
              !sessionToken.isEmpty else {
            errorMessage = "Session token not found. Please log in again."
            LogManager.logger.e("DeviceManagement: Missing or empty SSO token", error: nil)
            return false
        }
        
        // Create device client configuration
        let deviceConfig = DeviceClientConfig(
            serverUrl: serverUrl,
            realm: realm,
            cookieName: cookieName,
            ssoToken: sessionToken
        )
        
        // Initialize device client
        self.deviceClient = DeviceClient(config: deviceConfig)
        
        LogManager.logger.i("DeviceManagement: Successfully initialized")
        return true
    }
    
    // MARK: - Device Operations
    
    /// Loads devices for the selected device type
    func loadDevices(for type: DeviceType) async {
        // Ensure client is initialized
        guard let client = deviceClient else {
            errorMessage = "Device client not initialized. Please try again."
            LogManager.logger.e("DeviceManagement: Attempted to load devices without initialization", error: nil)
            
            // Try to initialize
            if await initialize() {
                // Retry loading after successful initialization
                await loadDevices(for: type)
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        selectedDeviceType = type
        
        let result: Result<Int, DeviceError> = switch type {
        case .oath:
            await client.oath.get().map { devices in
                self.oathDevices = devices
                LogManager.logger.i("DeviceManagement: Loaded \(devices.count) Oath devices")
                return devices.count
            }
            
        case .push:
            await client.push.get().map { devices in
                self.pushDevices = devices
                LogManager.logger.i("DeviceManagement: Loaded \(devices.count) Push devices")
                return devices.count
            }
            
        case .bound:
            await client.bound.get().map { devices in
                self.boundDevices = devices
                LogManager.logger.i("DeviceManagement: Loaded \(devices.count) Bound devices")
                return devices.count
            }
            
        case .profile:
            await client.profile.get().map { devices in
                self.profileDevices = devices
                LogManager.logger.i("DeviceManagement: Loaded \(devices.count) Profile devices")
                return devices.count
            }
            
        case .webAuthn:
            await client.webAuthn.get().map { devices in
                self.webAuthnDevices = devices
                LogManager.logger.i("DeviceManagement: Loaded \(devices.count) WebAuthn devices")
                return devices.count
            }
        }
        
        switch result {
        case .success:
            successMessage = "Successfully loaded \(type.rawValue) devices"
        case .failure(let error):
            handleDeviceError(error, operation: "load devices")
        }
        
        isLoading = false
    }
    
    /// Deletes an Oath device
    func deleteOathDevice(_ device: OathDevice) async {
        await performDeviceOperation(
            operation: { await self.deviceClient?.oath.delete(device) },
            onSuccess: {
                self.oathDevices.removeAll { $0.id == device.id }
            },
            deviceName: device.deviceName,
            operationType: "delete",
            deviceType: "Oath"
        )
    }
    
    /// Deletes a Push device
    func deletePushDevice(_ device: PushDevice) async {
        await performDeviceOperation(
            operation: { await self.deviceClient?.push.delete(device) },
            onSuccess: {
                self.pushDevices.removeAll { $0.id == device.id }
            },
            deviceName: device.deviceName,
            operationType: "delete",
            deviceType: "Push"
        )
    }
    
    /// Deletes a Bound device
    func deleteBoundDevice(_ device: BoundDevice) async {
        await performDeviceOperation(
            operation: { await self.deviceClient?.bound.delete(device) },
            onSuccess: {
                self.boundDevices.removeAll { $0.id == device.id }
            },
            deviceName: device.deviceName,
            operationType: "delete",
            deviceType: "Bound"
        )
    }
    
    /// Updates a Bound device
    func updateBoundDevice(_ device: BoundDevice, newName: String) async {
        var updatedDevice = device
        updatedDevice.deviceName = newName
        
        await performDeviceOperation(
            operation: { await self.deviceClient?.bound.update(updatedDevice) },
            onSuccess: {
                if let index = self.boundDevices.firstIndex(where: { $0.id == device.id }) {
                    self.boundDevices[index] = updatedDevice
                }
            },
            deviceName: device.deviceName,
            operationType: "update",
            deviceType: "Bound"
        )
    }
    
    /// Deletes a Profile device
    func deleteProfileDevice(_ device: ProfileDevice) async {
        await performDeviceOperation(
            operation: { await self.deviceClient?.profile.delete(device) },
            onSuccess: {
                self.profileDevices.removeAll { $0.id == device.id }
            },
            deviceName: device.deviceName,
            operationType: "delete",
            deviceType: "Profile"
        )
    }
    
    /// Updates a Profile device
    func updateProfileDevice(_ device: ProfileDevice, newName: String) async {
        var updatedDevice = device
        updatedDevice.deviceName = newName
        
        await performDeviceOperation(
            operation: { await self.deviceClient?.profile.update(updatedDevice) },
            onSuccess: {
                if let index = self.profileDevices.firstIndex(where: { $0.id == device.id }) {
                    self.profileDevices[index] = updatedDevice
                }
            },
            deviceName: device.deviceName,
            operationType: "update",
            deviceType: "Profile"
        )
    }
    
    /// Deletes a WebAuthn device
    func deleteWebAuthnDevice(_ device: WebAuthnDevice) async {
        await performDeviceOperation(
            operation: { await self.deviceClient?.webAuthn.delete(device) },
            onSuccess: {
                self.webAuthnDevices.removeAll { $0.id == device.id }
            },
            deviceName: device.deviceName,
            operationType: "delete",
            deviceType: "WebAuthn"
        )
    }
    
    /// Updates a WebAuthn device
    func updateWebAuthnDevice(_ device: WebAuthnDevice, newName: String) async {
        var updatedDevice = device
        updatedDevice.deviceName = newName
        
        await performDeviceOperation(
            operation: { await self.deviceClient?.webAuthn.update(updatedDevice) },
            onSuccess: {
                if let index = self.webAuthnDevices.firstIndex(where: { $0.id == device.id }) {
                    self.webAuthnDevices[index] = updatedDevice
                }
            },
            deviceName: device.deviceName,
            operationType: "update",
            deviceType: "WebAuthn"
        )
    }
    
    /// Updates a Push device
    func updatePushDevice(_ device: PushDevice, newName: String) async {
        var updatedDevice = device
        updatedDevice.deviceName = newName
        
        await performDeviceOperation(
            operation: { await self.deviceClient?.push.update(updatedDevice) },
            onSuccess: {
                if let index = self.pushDevices.firstIndex(where: { $0.id == device.id }) {
                    self.pushDevices[index] = updatedDevice
                }
            },
            deviceName: device.deviceName,
            operationType: "update",
            deviceType: "Push"
        )
    }
    
    /// Updates a Oath device
    func updateOathDevice(_ device: OathDevice, newName: String) async {
        var updatedDevice = device
        updatedDevice.deviceName = newName
        
        await performDeviceOperation(
            operation: { await self.deviceClient?.oath.update(updatedDevice) },
            onSuccess: {
                if let index = self.oathDevices.firstIndex(where: { $0.id == device.id }) {
                    self.oathDevices[index] = updatedDevice
                }
            },
            deviceName: device.deviceName,
            operationType: "update",
            deviceType: "Oath"
        )
    }
    
    // MARK: - Helper Methods
    
    /// Generic method to perform device operations with consistent error handling
    private func performDeviceOperation<T>(
        operation: () async -> Result<T, DeviceError>?,
        onSuccess: () -> Void,
        deviceName: String,
        operationType: String,
        deviceType: String
    ) async {
        guard deviceClient != nil else {
            errorMessage = "Device client not initialized"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        guard let result = await operation() else {
            errorMessage = "Device client not available"
            isLoading = false
            return
        }
        
        switch result {
        case .success:
            onSuccess()
            successMessage = "Successfully \(operationType)d device: \(deviceName)"
            LogManager.logger.i("DeviceManagement: \(operationType.capitalized) \(deviceType) device: \(deviceName)")
        case .failure(let error):
            handleDeviceError(error, operation: "\(operationType) device")
        }
        
        isLoading = false
    }
    
    /// Handles DeviceError with appropriate user messages
    private func handleDeviceError(_ error: DeviceError, operation: String) {
        switch error {
        case .networkError:
            errorMessage = "Network error. Please check your connection and try again."
        case .requestFailed(let statusCode, _):
            if statusCode == 401 {
                errorMessage = "Session expired. Please log in again."
            } else if statusCode == 404 {
                errorMessage = "Device not found. It may have been already deleted."
            } else if statusCode >= 500 {
                errorMessage = "Server error. Please try again later."
            } else {
                errorMessage = "Failed to \(operation). Status code: \(statusCode)"
            }
        case .invalidToken:
            errorMessage = "Invalid session. Please log in again."
        case .decodingFailed:
            errorMessage = "Failed to process server response. Please try again."
        default:
            errorMessage = error.localizedDescription
        }
        LogManager.logger.e("DeviceManagement: Failed to \(operation)", error: error)
    }
    
    /// Refreshes the current device type
    func refresh() async {
        await loadDevices(for: selectedDeviceType)
    }
    
    /// Clears any messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
}
