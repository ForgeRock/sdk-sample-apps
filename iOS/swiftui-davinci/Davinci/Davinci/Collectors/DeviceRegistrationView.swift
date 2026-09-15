//
//  DeviceRegistrationView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import PingDavinci
import SwiftUI

public struct DeviceRegistrationView: View {
    let field: DeviceRegistrationCollector
    public let onNext: (Bool) -> Void
    
    @State private var selectedType: String?
    
    public var body: some View {
        VStack(spacing: PingTheme.Spacing.medium) {
            Text("Select an MFA Device")
                .pingScreenTitle()
                .padding(.top)

            ScrollView {
                LazyVStack(spacing: PingTheme.Spacing.compact) {
                    ForEach(field.devices, id: \.title) { device in
                        DeviceCardView(device: device, isSelected: selectedType == device.type)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle()) // Ensures the tap gesture covers the full width.
                            .onTapGesture {
                                selectedType = device.type
                                field.value = device
                                onNext(true)
                            }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

