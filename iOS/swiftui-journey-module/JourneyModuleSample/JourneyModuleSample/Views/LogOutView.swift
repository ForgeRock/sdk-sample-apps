// 
//  LogOutView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// A view for managing the logout process.
struct LogOutView: View {
    /// A binding to the navigation stack path.
    @Binding var path: [MenuItem]
    /// State object for managing the logout functionality.
    @StateObject private var logoutViewModel =  LogOutViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle("De-enroll keyless device during logout", isOn: $logoutViewModel.shouldDeEnrollKeyless)
                .padding(.horizontal)
            
            Spacer()
            
            NextButton(title: "Proceed to logout") {
                Task {
                    await logoutViewModel.logout()
                    if path.count > 0 {
                        path.removeLast()
                    }
                }
            }
        }
        .navigationTitle(path.last?.title ?? "")
    }
}
