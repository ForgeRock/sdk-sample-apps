// 
//  KeylessInfoView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// A view that displays Keyless SDK information
struct KeylessInfoView: View {
    let menuItem: MenuItem
    /// A state object that manages the Keyless information data.
    /// The `KeylessInfoViewModel` is responsible for collecting Keyless SDK info.
    @StateObject private var keylessInfoViewModel = KeylessInfoViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Device Identifier Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Device Identifier")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(keylessInfoViewModel.deviceIdentifier)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                }
                
                // User ID Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("User ID")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(keylessInfoViewModel.userID)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(menuItem.title)
    }
}
