// 
//  ConfigurationViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRAuth

 /*
    The ConfigurationViewModel class is an ObservableObject that contains the configuration properties for the SDK. The class has the following properties:
    
        clientId: The client ID for the SDK.
        scopes: The scopes for the SDK.
        redirectUri: The redirect URI for the SDK.
        signOutUri: The sign-out URI for the SDK.
        discoveryEndpoint: The discovery endpoint for the SDK.
        environment: The environment for the SDK.
        cookieName: The cookie name for the SDK.
        browserSeletorType: The browser selector type for the SDK.
  
    The class has the following methods:
        getBrowserType(): Returns the browser type for the SDK.
        saveConfiguration(): Saves the configuration for the SDK.
        startSDK(): Starts the SDK.
        resetConfiguration(): Resets the configuration for the SDK.
 */

class ConfigurationViewModel: ObservableObject {
    
    @Published public var clientId: String
    @Published public var scopes: [String]
    @Published public var redirectUri: String
    @Published public var signOutUri: String?
    @Published public var discoveryEndpoint: String
    @Published public var environment: String
    @Published public var cookieName: String?
    @Published public var browserSeletorType: BrowserSelectorTypes
    
    public init(clientId: String, scopes: [String], redirectUri: String, signOutUri: String?, discoveryEndpoint: String, environment: String, cookieName: String? = nil, browserSeletorType: BrowserSelectorTypes) {
        self.clientId = clientId
        self.scopes = scopes
        self.redirectUri = redirectUri
        self.signOutUri = signOutUri
        self.discoveryEndpoint = discoveryEndpoint
        self.environment = environment
        self.cookieName = cookieName
        self.browserSeletorType = browserSeletorType
    }
    
    public func getBrowserType() -> BrowserType {
        return BrowserType.init(rawValue: self.browserSeletorType.asInt()) ?? .authSession
    }
    
    public func saveConfiguration() {
        ConfigurationManager.shared.saveConfiguration()
    }
    
    public func startSDK() async {
        Task {
            do {
                let _ = try await ConfigurationManager.shared.startSDK()
            } catch {
                print(String(describing: error))
            }
        }
    }
    
    public func resetConfiguration() -> ConfigurationViewModel {
        ConfigurationManager.shared.deleteSavedConfiguration()
        ConfigurationManager.shared.currentConfigurationViewModel = nil
        let defaultConfig = ConfigurationManager.shared.defaultConfigurationViewModel()
        ConfigurationManager.shared.currentConfigurationViewModel = defaultConfig
        return defaultConfig
    }
}

struct Configuration: Codable {
    var clientId: String
    var scopes: [String]
    var redirectUri: String
    var signOutUri: String?
    var discoveryEndpoint: String
    var environment: String
    var cookieName: String?
    var browserType: BrowserType
}
