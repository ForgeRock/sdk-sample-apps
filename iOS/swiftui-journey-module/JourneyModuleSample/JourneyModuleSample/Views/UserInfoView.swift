// 
//  UserInfoView.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// A view that displays user information
struct UserInfoView: View {
    let menuItem: MenuItem
    /// A state object that manages the user information data.
    /// The `UserInfoViewModel` is responsible for fetching and updating user data.
    @StateObject private var userInfoViewModel = UserInfoViewModel()
    
    var body: some View {
        ScrollView {
            Text(userInfoViewModel.userInfo)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .navigationTitle(menuItem.title)
        }
    }
}
