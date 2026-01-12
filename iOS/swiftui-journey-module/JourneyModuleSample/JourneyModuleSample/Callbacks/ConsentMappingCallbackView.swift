//
//  ConsentMappingCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

/**
 * A SwiftUI view for obtaining user consent for attribute mapping during authentication flows.
 *
 * This view displays detailed information about data mapping consent, including the mapping name,
 * display name, icon, access level, required fields, and a descriptive message. Users must review
 * this information and toggle their consent. This is commonly used when integrating with external
 * systems that require explicit permission to share user attributes.
 *
 * **User Action Required:** YES - User must toggle the consent switch to accept or decline the mapping.
 *
 * The UI displays all consent details including name, display name, icon reference, access level,
 * required status, mapped fields, message, and a toggle switch for consent. The toggle reflects
 * the current consent state.
 */
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
