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
    @Binding var viewmodel: ConfigurationViewModel
    @State private var scopes: String = ""
    @State private var environments = ["AIC", "PingOne"]
    @State private var selectedEnvironment = "AIC"
    @State private var selectedBrowserType: BrowserSelectorTypes = .authSession
    
    var body: some View {
        Form {
            Section(header: Text("OAuth 2.0 details")) {
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
                    Text("SignOut URI:")
                    TextField("SignOut URI", text: $viewmodel.signOutUri.toUnwrapped(defaultValue: ""))
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
            Section(header: Text("Environment details")) {
                Section {
                    Picker("Environment: ", selection: $selectedEnvironment) {
                        ForEach(environments, id: \.self) { env in
                            Text(env)
                        }
                    }.onChange(of: selectedEnvironment) { env in
                        viewmodel.environment = env
                    }
                    .pickerStyle(.menu)
                }
                Section {
                    Text("Cookie Name (Optional):")
                    TextField("Cookie Name:", text: $viewmodel.cookieName.toUnwrapped(defaultValue: ""))
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
                    viewmodel.browserSeletorType = type
                }
                .pickerStyle(.menu)
            }
            Section(header: Text("Browser Configuration")) {
                Button(action: {
                    Task {
                        viewmodel.scopes = scopes.components(separatedBy: " ")
                        viewmodel.saveConfiguration()
                        await viewmodel.startSDK()
                    }
                }) {
                    Text("Save Configuration")
                }
                Button(action: {
                    Task {
                        let defaultConfiguration = viewmodel.resetConfiguration()
                        viewmodel = defaultConfiguration
                        scopes = $viewmodel.scopes.wrappedValue.joined(separator: " ")
                    }
                }) {
                    Text("Reset Configuration")
                }
            }
        }
        .navigationTitle("Edit Configuration")
        .onAppear{
            scopes = $viewmodel.scopes.wrappedValue.joined(separator: " ")
            selectedBrowserType = viewmodel.browserSeletorType
            selectedEnvironment = viewmodel.environment
        }
        .onDisappear{
            viewmodel.scopes = scopes.components(separatedBy: " ")
            viewmodel.saveConfiguration()
            Task {
                await viewmodel.startSDK()
            }
        }
    }
}
