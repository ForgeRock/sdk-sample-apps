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
import FRAuth

struct ConfigurationView: View {
    @Binding var configurationViewModel: ConfigurationViewModel
    @State private var scopes: String = ""
    @State private var environments = ["AIC", "PingOne"]
    @State private var selectedEnvironment = "AIC"
    @State private var selectedBrowserType: BrowserSelectorTypes = .authSession
    
    var body: some View {
        Form {
            Section(header: Text("OAuth 2.0 details")) {
                Section {
                    Text("Client Id:")
                    TextField("Client Id", text: $configurationViewModel.clientId)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                Section {
                    Text("Redirect URI:")
                    TextField("Redirect URI", text: $configurationViewModel.redirectUri)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                Section {
                    Text("SignOut URI:")
                    TextField("SignOut URI", text: $configurationViewModel.signOutUri.toUnwrapped(defaultValue: ""))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                Section {
                    Text("Discovery Endpoint:")
                    TextField("Discovery Endpoint", text: $configurationViewModel.discoveryEndpoint)
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
            Section(header: Text("Environment details")) {
                Section {
                    Picker("Environment: ", selection: $selectedEnvironment) {
                        ForEach(environments, id: \.self) { env in
                            Text(env)
                        }
                    }.onChange(of: selectedEnvironment) { env in
                        configurationViewModel.environment = env
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    Text("Cookie Name (Optional):")
                    TextField("Cookie Name:", text: $configurationViewModel.cookieName.toUnwrapped(defaultValue: ""))
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
            }
            Section(header: Text("Browser Configuration")) {
                Picker("Browser Configuration: ", selection: $selectedBrowserType) {
                    ForEach(BrowserSelectorTypes.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }.onChange(of: selectedBrowserType) { type in
                    configurationViewModel.browserSeletorType = type
                }
                .pickerStyle(.menu)
            }
            Section(header: Text("Browser Configuration")) {
                Button(action: {
                    Task {
                        configurationViewModel.scopes = scopes.components(separatedBy: " ")
                        configurationViewModel.saveConfiguration()
                        await configurationViewModel.startSDK()
                    }
                }) {
                    Text("Save Configuration")
                }
                Button(action: {
                    Task {
                        let defaultConfiguration = configurationViewModel.resetConfiguration()
                        configurationViewModel = defaultConfiguration
                        scopes = $configurationViewModel.scopes.wrappedValue.joined(separator: " ")
                    }
                }) {
                    Text("Reset Configuration")
                }
            }
        }
        .navigationTitle("Edit Configuration")
        .onAppear{
            scopes = $configurationViewModel.scopes.wrappedValue.joined(separator: " ")
            selectedBrowserType = configurationViewModel.browserSeletorType
            selectedEnvironment = configurationViewModel.environment
        }
        .onDisappear{
            configurationViewModel.scopes = scopes.components(separatedBy: " ")
            configurationViewModel.saveConfiguration()
            Task {
                await configurationViewModel.startSDK()
            }
        }
    }
}
