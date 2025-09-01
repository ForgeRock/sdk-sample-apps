// 
//  DeviceAuthenticationView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import PingDavinci
import SwiftUI

public struct DeviceAuthenticationView: View {
    let field: DeviceAuthenticationCollector
    public let onNext: (Bool) -> Void
    
    @State private var selectedType: String?
    
    public var body: some View {
        VStack(spacing: 16) {
            Text("Select an MFA Device")
                .font(.title)
                .padding(.top)
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(field.devices, id: \.id) { device in
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
                .accentColor(.clear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
