//
//  DeviceCardView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import PingDavinci
import SwiftUI

// A simple card view for a Device.
struct DeviceCardView: View {
    let device: Device
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Load the device icon from the URL.
            AsyncSVGImage(url: device.iconSrc)
                .frame(width: 80)
            Text(device.title)
                .font(.headline)
            Text(device.description ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}
