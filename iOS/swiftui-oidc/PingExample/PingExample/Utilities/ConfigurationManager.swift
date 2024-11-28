//
//  ConfigurationManager.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import FRAuth
import FRCore
import SwiftUI
import UIKit

/*
    The ConfigurationManager class is used to manage the configuration settings for the SDK.
    The class provides the following functionality:
       - Load the current configuration
       - Save the current configuration
       - Delete the saved configuration
       - Provide the default configuration
       - Start the SDK with the current configuration
 */
 
class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    public var user: FRUser?
    public var currentConfigurationViewModel: ConfigurationViewModel?
    
    public func loadConfigurationViewModel() -> ConfigurationViewModel {
        if self.currentConfigurationViewModel == nil {
            self.currentConfigurationViewModel = defaultConfigurationViewModel()
        }
        return self.currentConfigurationViewModel!
    }
    
    /// Start the SDK with the current configuration
    public func startSDK() async throws -> Bool {
        if let currentConfiguration = self.currentConfigurationViewModel {
            let config: [String : Any]
            if currentConfiguration.environment == "AIC" {
                config =
                ["forgerock_oauth_client_id": currentConfiguration.clientId,
                 "forgerock_oauth_redirect_uri": currentConfiguration.redirectUri,
                 "forgerock_oauth_scope": currentConfiguration.scopes.joined(separator: " "),
                 "forgerock_cookie_name": currentConfiguration.cookieName ?? ""]
            } else {
                config =
                ["forgerock_oauth_client_id": currentConfiguration.clientId,
                 "forgerock_oauth_redirect_uri": currentConfiguration.redirectUri,
                 "forgerock_oauth_sign_out_redirect_uri": currentConfiguration.signOutUri ?? "",
                 "forgerock_oauth_scope": currentConfiguration.scopes.joined(separator: " "),
                 "forgerock_cookie_name": currentConfiguration.cookieName ?? ""]
            }
            
            
            let discoveryURL = currentConfiguration.discoveryEndpoint
            
            let options = try await FROptions(config: config).discover(discoveryURL: discoveryURL)
            return try await withCheckedThrowingContinuation({
                (continuation: CheckedContinuation<Bool, Error>) in
                do {
                    try FRAuth.start(options: options)
                    print("FRAuth SDK started using \(discoveryURL) discovery URL")
                    FRLog.setLogLevel([.all])
                    continuation.resume(returning: true)
                } catch {
                    print(String(describing: error))
                    continuation.resume(throwing: error)
                }
            })
        } else {
            return false
        }
    }
    
    /// Save the current configuration
    public func saveConfiguration() {
        if let currentConfiguration = self.currentConfigurationViewModel {
            let encoder = JSONEncoder()
            let configuration = Configuration(clientId: currentConfiguration.clientId, scopes: currentConfiguration.scopes, redirectUri: currentConfiguration.redirectUri, signOutUri: currentConfiguration.signOutUri, discoveryEndpoint: currentConfiguration.discoveryEndpoint, environment: currentConfiguration.environment, cookieName: currentConfiguration.cookieName, browserType: currentConfiguration.getBrowserType())
            if let encoded = try? encoder.encode(configuration) {
                let defaults = UserDefaults.standard
                defaults.set(encoded, forKey: "CurrentConfiguration")
            }
        }
    }
    
    /// Delete the saved configuration
    public func deleteSavedConfiguration() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "CurrentConfiguration")
    }
    
    /// Provide the default configuration. If empty or not found, provide the placeholder configuration
    public func defaultConfigurationViewModel() -> ConfigurationViewModel {
        let defaults = UserDefaults.standard
        if let savedConfiguration = defaults.object(forKey: "CurrentConfiguration") as? Data {
            let decoder = JSONDecoder()
            if let loadedConfiguration = try? decoder.decode(Configuration.self, from: savedConfiguration) {
                return ConfigurationViewModel(clientId: loadedConfiguration.clientId, scopes: loadedConfiguration.scopes, redirectUri: loadedConfiguration.redirectUri, signOutUri: loadedConfiguration.signOutUri, discoveryEndpoint: loadedConfiguration.discoveryEndpoint, environment: loadedConfiguration.environment, cookieName: loadedConfiguration.cookieName, browserSeletorType: BrowserSelectorTypes(rawValue: loadedConfiguration.browserType.description) ?? BrowserSelectorTypes.authSession)
            }
        }
        
        //TODO: Provide here the client configuration. Replace the placeholder with the OAuth2.0 client details
        return ConfigurationViewModel(
            clientId: "[CLIENT ID]",
            scopes: ["openid", "email", "address", "phone", "profile"], // Alter the scopes based on your clients configuration
            redirectUri: "[REDIRECT URI]",
            signOutUri: "[SIGN OUT URI]",
            discoveryEndpoint: "[DISCOVERY ENDPOINT URL]",
            environment: "[ENVIRONMENT - EITHER AIC OR PingOne]",
            cookieName: "[COOKIE NAME - OPTIONAL (Applicable for AIC only)]",
            browserSeletorType: .authSession
        )
    }
}

//Extensions

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

enum BrowserSelectorTypes: String, CaseIterable  {
    case authSession
    case nativeBrowserApp
    case sfViewController
    case ephemeralAuthSession
    
    static var asArray: [BrowserSelectorTypes] {return self.allCases}
    
    func asInt() -> Int {
        return BrowserSelectorTypes.asArray.firstIndex(of: self)!
    }
}

extension ObservableObject {
    var topViewController: UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = keyWindow.rootViewController else {
            return nil
        }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

extension Binding {
     func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
