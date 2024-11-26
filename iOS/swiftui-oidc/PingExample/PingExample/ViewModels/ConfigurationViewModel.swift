// 
//  ConfigurationViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRAuth
class ConfigurationViewModel: ObservableObject {
    
    @Published public var clientId: String
    @Published public var scopes: [String]
    @Published public var redirectUri: String
    @Published public var signOutUri: String?
    @Published public var discoveryEndpoint: String
    @Published public var environment: String
    @Published public var cookieName: String?
    @Published public var browserSeletorType: BrowserSeletorTypes
    
    public init(clientId: String, scopes: [String], redirectUri: String, signOutUri: String?, discoveryEndpoint: String, environment: String, cookieName: String? = nil, browserSeletorType: BrowserSeletorTypes) {
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

extension BrowserType: Codable {
    var description: String {
          switch self {
          case .authSession:
              return "authSession"
          case .nativeBrowserApp:
              return "nativeBrowserApp"
          case .sfViewController:
              return "sfViewController"
          case .ephemeralAuthSession:
             return "ephemeralAuthSession"
       default:
             return "authSession"
          }
       }
}

enum BrowserSeletorTypes: String, CaseIterable  {
    case authSession
    case nativeBrowserApp
    case sfViewController
    case ephemeralAuthSession
    
    static var asArray: [BrowserSeletorTypes] {return self.allCases}
    
    func asInt() -> Int {
        return BrowserSeletorTypes.asArray.firstIndex(of: self)!
    }
}
