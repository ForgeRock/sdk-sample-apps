//
//  DeviceInfoViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import Combine
import PingLogger
import PingDeviceProfile
import PingCommons

/// A view model responsible for fetching and managing device information.
/// - Provides a published `deviceInfo` property that is updated with device information or error messages.
/// - Collects device information asynchronously.
@MainActor
class DeviceInfoViewModel: ObservableObject {
    @Published var isLoading: Bool = true
    /// Error message if device info collection fails.
    @Published var error: String?
    /// Top-level entries (version, identifier)
    @Published var topLevel: [(key: String, value: String)] = []
    /// Sections from the "metadata" dictionary (platform, hardware, network, etc.)
    @Published var sections: [(name: String, entries: [(key: String, value: String)])] = []
    /// Raw pretty-printed JSON string
    @Published var rawJSON: String = ""
    
    init() {
        Task {
            await collectDeviceInfo()
        }
    }
    
    /// Collects device information
    /// - The method retrieves device info as a dictionary and formats them as a string for display.
    /// - Updates the `DeviceInfo` property with the collected info or an error message.
    /// - Logs success and error messages using `PingLogger`.
    func collectDeviceInfo() async {
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
            
            // Store raw JSON for the raw view
            let prettyData = try JSONSerialization.data(withJSONObject: profileDict, options: [.prettyPrinted, .sortedKeys])
            rawJSON = String(data: prettyData, encoding: .utf8) ?? ""
            
            parseProfile(profileDict)
            isLoading = false
            
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            LogManager.standard.e("Failed to Collect Device Info", error: error)
        }
    }
    
    private func parseProfile(_ dict: [String: Any]) {
        // Extract top-level scalar values
        for key in dict.keys.sorted() where key != "metadata" {
            if let value = dict[key] {
                topLevel.append((key: key, value: stringValue(value)))
            }
        }
        
        // Extract metadata sections
        if let metadata = dict["metadata"] as? [String: Any] {
            let sectionOrder = ["platform", "hardware", "network", "telephony", "browser", "bluetooth", "location"]
            let sortedKeys = metadata.keys.sorted { (sectionOrder.firstIndex(of: $0) ?? 99) < (sectionOrder.firstIndex(of: $1) ?? 99) }
            
            for sectionKey in sortedKeys {
                guard let sectionDict = metadata[sectionKey] as? [String: Any] else { continue }
                var entries: [(key: String, value: String)] = []
                flattenDict(sectionDict, prefix: "", into: &entries)
                sections.append((name: sectionKey, entries: entries))
            }
        }
    }
    
    private func flattenDict(_ dict: [String: Any], prefix: String, into entries: inout [(key: String, value: String)]) {
        for key in dict.keys.sorted() {
            let fullKey = prefix.isEmpty ? key : "\(prefix).\(key)"
            if let nested = dict[key] as? [String: Any] {
                flattenDict(nested, prefix: fullKey, into: &entries)
            } else if let value = dict[key] {
                entries.append((key: fullKey, value: stringValue(value)))
            }
        }
    }
    
    private func stringValue(_ value: Any) -> String {
        if let num = value as? NSNumber {
            // CFBoolean is a subclass of NSNumber; check type to distinguish Bool from Int
            if type(of: value) == type(of: NSNumber(value: true)) {
                return num.boolValue ? "true" : "false"
            }
            return num.stringValue
        }
        if let str = value as? String {
            return str
        }
        return "\(value)"
    }
}
