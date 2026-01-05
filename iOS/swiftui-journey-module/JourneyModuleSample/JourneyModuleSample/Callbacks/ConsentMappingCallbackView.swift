//
//  ConsentMappingCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

struct ConsentMappingCallbackView: View {
    let callback: ConsentMappingCallback
    let onNodeUpdated: () -> Void

    @State var accepted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Name
            if !callback.name.isEmpty {
                Text("Name: \(callback.name)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Display Name
            if !callback.displayName.isEmpty {
                Text("DisplayName: \(callback.displayName)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Icon
            if !callback.icon.isEmpty {
                Text("Icon: \(callback.icon)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Access Level
            if !callback.accessLevel.isEmpty {
                Text("AccessLevel: \(callback.accessLevel)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Is Required
            Text("IsRequired: \(callback.isRequired.description)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // fields
            ForEach(callback.fields, id: \.self) { fieldItem in
                Text("callback: \(fieldItem)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Message
            if !callback.message.isEmpty {
                Text("Message: \(callback.message)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Acceptance Toggle
            Toggle("I consent to this mapping", isOn: $accepted)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: accepted) { newValue in
                    callback.accepted = newValue
                }
        }
        .padding()
        .onAppear {
            accepted = callback.accepted
        }
    }
}
