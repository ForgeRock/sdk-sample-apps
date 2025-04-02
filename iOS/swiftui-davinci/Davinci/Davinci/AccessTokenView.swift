//
//  AccessTokenView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// A view that displays the access token.
/// - Provides a simple interface to view the current OAuth access token.
struct AccessTokenView: View {
    /// A state object that manages the access token data.
    /// - Responsible for fetching and maintaining the current access token.
    @StateObject var accessTokenViewModel = AccessTokenViewModel()
    
    var body: some View {
        VStack {
            /// Scrollable container to accommodate large token strings
            ScrollView {
                /// Display the access token with secondary styling for readability
                Text($accessTokenViewModel.accessToken.wrappedValue)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .navigationTitle("Access Token")
            }
        }
    }
}
