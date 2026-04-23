//
//  AccessToken.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth
struct AccessTokenView: View {
    
    @Binding var path: [String]
    
    @StateObject var accessTokenViewModel: AccessTokenViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                Text($accessTokenViewModel.accessToken.wrappedValue)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .navigationTitle("AccessToken")
            }
           
            Spacer(minLength: 35.0)
            Button(action: {
                Task {
                    self.accessTokenViewModel.refreshTokens()
                }
            }) {
                Text("Refresh Token")
            }
            Spacer(minLength: 35.0)
            Button(action: {
                Task {
                    self.accessTokenViewModel.revokeTokens()
                }
            }) {
                Text("Revoke Token")
            }
            Spacer(minLength: 25.0)
        }
    }
}
