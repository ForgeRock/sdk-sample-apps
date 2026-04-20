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
import FRAuth

struct UserInfoView: View {
    @Binding var path: [String]
    
    @StateObject var userInfoViewModel: UserInfoViewModel
    
    var body: some View {
        ScrollView {
            Text($userInfoViewModel.userInfo.wrappedValue)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .navigationTitle("User Info")
        }
    }
}
