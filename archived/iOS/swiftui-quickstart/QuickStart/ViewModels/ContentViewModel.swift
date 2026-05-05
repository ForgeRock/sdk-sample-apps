//
//  ContentViewModel.swift
//  QuickStart
//
// Copyright (c) 2023 - 2025 Ping Identity Corporation. All rights reserved.
//
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

@MainActor class ContentViewModel: ObservableObject {
    @Published private(set) var sdkStarted = false
    
    func startSDK(statusViewModel: StatusViewModel) {
        FRLog.setLogLevel([.network, .all])
        
        do {
            // By default the SDK uses FRAuthConfig.plist file for the configuration.
            // You can also use an FROptions object to dynamically configure the SDK.
            // In this project we will be using the FROptions route. If insted you want to use the FRAuthConfig.plist config file,
            // you can edit the provided FRAuthConfig.plist file in the Resources folder.
            // Calling `try FRAuth.start()` will load the configuration from the default FRAuthConfig.plist file.
            // You can also specify a separate file like this: `FRAuth.configPlistFileName = "DesiredFRAuthConfig"`
            // Please see the docs for more details here: https://docs.pingidentity.com/sdks/latest/sdks/sdkconfiguration/configure-sdk-ios.html#example
            let options = FROptions(
                // The tenant URL
                url: "https://tenant.forgeblocks.com/am",
                // Realm Name
                realm: "alpha",
                // The cookie name for the tenant
                cookieName: "46b42b4229cd7a3",
                // The values below are the default journeys in your tenant.
                // Modify as needed.
                // Uses default Login journey for sample app.
                // Updated as needed based on the journey you create.
                authServiceName: "Login",
                // Uses default Registration journey for sample app.
                // Updated as needed based on the journey you create.
                registrationServiceName: "Register",
                // Client ID for the OAuth2 client.
                oauthClientId: "sdkNativeClient",
                // Redirect URI back to client, update
                // if you have another URI to add.
                oauthRedirectUri: "org.forgerock.demo://oauth2redirect",
                // By default, all scopes configured in the client are added,
                // modify as needed.
                oauthScope: "openid profile email address")
            // Replace the above values with your actual configuration values.
            try FRAuth.start(options: options)
            
            print("SDK initialized successfully")
            statusViewModel.status = Status(statusDescription: "SDK ready", statusType: .success)
            sdkStarted = true
        } catch {
            print(error)
            statusViewModel.status = Status(statusDescription: error.localizedDescription, statusType: .error)
            sdkStarted = false
        }
    }
}
