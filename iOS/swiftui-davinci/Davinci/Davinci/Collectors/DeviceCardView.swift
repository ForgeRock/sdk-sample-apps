//
//  DeviceCardView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
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
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            // Load the device icon from the URL.
            AsyncSVGImage(url: device.iconSrc)
                .frame(width: 80)
            Text(device.title)
                .pingSectionHeader()
            Text(device.description ?? "")
                .pingSupportingText()
        }
        .padding(PingTheme.Spacing.medium)
        .background(isSelected ? PingTheme.Color.actionPrimary.opacity(0.2) : PingTheme.Color.contentSecondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: PingTheme.Shape.tileRadius))
        .overlay(
            RoundedRectangle(cornerRadius: PingTheme.Shape.tileRadius)
                .stroke(isSelected ? PingTheme.Color.actionPrimary : Color.clear, lineWidth: 2)
        )
    }
}
