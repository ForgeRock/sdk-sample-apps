//
//  DeviceInfoViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingLogger
import PingDeviceProfile
import PingCommons
import Combine

/// A view model responsible for fetching and managing device information.
/// - Provides a published `deviceInfo` property that is updated with device information or error messages.
/// - Collects device information asynchronously.
@MainActor
class DeviceInfoViewModel: ObservableObject {
    /// Published property to hold the device information or error messages.
    @Published var deviceInfo: String = ""
    
    /// Initializes the `DeviceInfoViewModel` and collects device information.
    /// - The data is fetched asynchronously during initialization.
    init() {
        Task {
            await collecDeviceInfo()
        }
    }
    
    /// Collects device information
    /// - The method retrieves device info as a dictionary and formats them as a string for display.
    /// - Updates the `DeviceInfo` property with the collected info or an error message.
    /// - Logs success and error messages using `PingLogger`.
    func collecDeviceInfo() async {
        // Create configuration with server settings
        let config = DeviceProfileConfig()
        config.metadata = true
        config.location = true
        config.collectors {
            return [
                PlatformCollector(),
                HardwareCollector(),
                BrowserCollector(),
                TelephonyCollector(),
                NetworkCollector(),
                BluetoothCollector(),
                LocationCollector()
            ]
        }
        
        do {
            // Perform device profile collection
            let collector = DeviceProfileCollector(config: config)
            guard let deviceProfile = try await collector.collect() else {
                throw DeviceProfileError.collectionFailed
            }
            
            // Encode results to JSON
            let jsonData = try JSONEncoder().encode(deviceProfile)
            guard let profileDict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                throw DeviceProfileError.serializationFailed
            }
            
            // Submit to server
            deviceInfo = JSONUtils.jsonStringify(value: profileDict as AnyObject, prettyPrinted: true)
            LogManager.standard.i("Device Binding Result: \n\(deviceInfo)")
            
        } catch {
            deviceInfo = "Error: \(error.localizedDescription)"
            LogManager.standard.e("Failed to Collect Device Info", error: error)
        }
    }
}
