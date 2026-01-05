//
//  AccessTokenView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import Combine

/// A view that displays the access token.
struct AccessTokenView: View {
    let menuItem: MenuItem
    /// A state object that manages the access token data.
    @StateObject private var accessTokenViewModel = AccessTokenViewModel()
    
    var body: some View {
        VStack {
            ScrollView {
                Text(accessTokenViewModel.token)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .navigationTitle(menuItem.title)
            }
        }
    }
}
