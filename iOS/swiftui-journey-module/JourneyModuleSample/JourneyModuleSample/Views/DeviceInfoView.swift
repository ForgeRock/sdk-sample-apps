// 
//  DeviceInfoView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI

/// A view that displays device information
struct DeviceInfoView: View {
    let menuItem: MenuItem
    /// A state object that manages the device information data.
    /// The `DeviceInfoViewModel` is responsible for collecting device info.
    @StateObject private var deviceInfoViewModel = DeviceInfoViewModel()
    
    var body: some View {
        ScrollView {
            Text(deviceInfoViewModel.deviceInfo)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .navigationTitle(menuItem.title)
        }
    }
}
