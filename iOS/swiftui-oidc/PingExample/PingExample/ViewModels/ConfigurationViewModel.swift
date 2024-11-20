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

class ConfigurationViewModel: ObservableObject {
    
    @Published public var clientId: String
    @Published public var scopes: [String]
    @Published public var redirectUri: String
    @Published public var discoveryEndpoint: String
    
    public init(clientId: String, scopes: [String], redirectUri: String, discoveryEndpoint: String) {
        self.clientId = clientId
        self.scopes = scopes
        self.redirectUri = redirectUri
        self.discoveryEndpoint = discoveryEndpoint
    }
}

struct Configuration: Codable {
    var clientId: String
    var scopes: [String]
    var redirectUri: String
    var discoveryEndpoint: String
}

