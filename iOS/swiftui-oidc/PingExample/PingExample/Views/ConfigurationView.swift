// 
//  ConfigurationView.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI

struct ConfigurationView: View {
    @Binding var viewmodel: ConfigurationViewModel
    @State private var scopes: String = ""
    
    var body: some View {
        Form {
            Section {
                Text("Client Id:")
                TextField("Client Id", text: $viewmodel.clientId)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
            Section {
                Text("Redirect URI:")
                TextField("Redirect URI", text: $viewmodel.redirectUri)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
            Section {
                Text("Discovery Endpoint:")
                TextField("Discovery Endpoint", text: $viewmodel.discoveryEndpoint)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
            Section {
                Text("Scopes:")
                TextField("scopes:", text: $scopes)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
        }
        .navigationTitle("Edit Configuration")
        .onAppear{
            scopes = $viewmodel.scopes.wrappedValue.joined(separator: ",")
        }
        .onDisappear{
            viewmodel.scopes = scopes.components(separatedBy: ",")
            ConfigurationManager.shared.saveConfiguration()
        }
    }
}
