//
//  AppConfiguration.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingJourney
import PingStorage
import PingLogger

enum JourneyName {
    static let login = "Login"
    static let fidoRegistration = "BlogWebAuthnRegistration"
    static let fidoAuthentication = "BlogWebAuthnAuthentication"
}

enum UserDefaultsKey {
    static let biometricsEnabled = "BiometricsEnabled"
}

enum ServerConfig {
    static let serverUrl = "https://openam-bafaloukas.forgeblocks.com/am"
    static let realm = "alpha"
    static let cookieName = "386c0d288cac4b9"
    static let clientId = "iosClient"
    static let scopes: Set<String> = ["openid", "profile", "email", "address"]
    static let redirectUri = "frauth://com.forgerock.ios.frexample"
    static let discoveryEndpoint = "https://openam-bafaloukas.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
}

@MainActor
class AppJourney {
    static let shared = AppJourney()

    let journey: Journey

    private init() {
        journey = Journey.createJourney { journeyConfig in
            journeyConfig.serverUrl = ServerConfig.serverUrl
            journeyConfig.realm = ServerConfig.realm
            journeyConfig.cookie = ServerConfig.cookieName
            journeyConfig.logger = LogManager.standard
            journeyConfig.module(PingJourney.OidcModule.config) { oidcConfig in
                oidcConfig.clientId = ServerConfig.clientId
                oidcConfig.scopes = ServerConfig.scopes
                oidcConfig.redirectUri = ServerConfig.redirectUri
                oidcConfig.discoveryEndpoint = ServerConfig.discoveryEndpoint
                oidcConfig.logger = LogManager.standard
            }
        }
    }
}
