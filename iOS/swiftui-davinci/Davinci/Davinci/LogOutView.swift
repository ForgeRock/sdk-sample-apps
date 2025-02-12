// 
//  LogOutView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// A view for managing the logout process.
struct LogOutView: View {
  /// A binding to the navigation stack path.
  @Binding var path: [String]
  /// State object for managing the logout functionality.
  @StateObject private var logoutViewModel =  LogOutViewModel()
  
  var body: some View {
    Spacer()
    NextButton(title: "Procced to logout") {
      Task {
        await logoutViewModel.logout()
        path.removeLast()
        path.append("DaVinci")
      }
    }
    .navigationTitle("Logout")
  }
}
