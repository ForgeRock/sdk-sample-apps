//
//  AccessToken.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth
struct AccessTokenView: View {
    
    @Binding var path: [String]
    
    @StateObject var tokenViewModel = TokenViewModel()
    
    var body: some View {
        VStack {
            
            TextEditor(text: $tokenViewModel.accessToken)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .navigationTitle("AccessToken")
            Spacer(minLength: 35.0)
            Button(action: {
                Task {
                    self.tokenViewModel.refreshTokens()
                }
            }) {
                Text("Refresh Token")
            }
            Spacer(minLength: 35.0)
            Button(action: {
                Task {
                    self.tokenViewModel.revokeTokens()
                }
            }) {
                Text("Revoke Token")
            }
            Spacer(minLength: 25.0)
        }
    }
}
