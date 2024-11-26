// 
//  UserInfoView.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import FRAuth

struct UserInfoView: View {
    @Binding var path: [String]
    
    @StateObject var vm = UserInfoViewModel()
    
    var body: some View {
        
        TextEditor(text: $vm.userInfo)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .navigationTitle("User Info")
        
    }
}
