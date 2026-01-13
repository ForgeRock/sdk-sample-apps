//
//  BooleanAttributeInputCallbackView.swift
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
 * A SwiftUI view for capturing boolean (true/false) attribute values during authentication flows.
 *
 * This view displays a toggle switch with a descriptive prompt label, allowing users to enable
 * or disable a specific attribute or setting. Common use cases include opt-in preferences,
 * feature flags, or binary configuration options during registration or profile updates.
 *
 * **User Action Required:** YES - User must toggle the switch to set their preference.
 *
 * The UI displays the prompt text on the left with a toggle switch on the right. The toggle
 * reflects the current value and updates the callback immediately when changed.
 */
struct BooleanAttributeInputCallbackView: View {
    let callback: BooleanAttributeInputCallback
    let onNodeUpdated: () -> Void

    @State var value: Bool = false

    var body: some View {
        HStack {
            Text(callback.prompt)
                .foregroundColor(.primary)

            Spacer()

            Toggle("", isOn: $value)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: value) { newValue in
                    callback.value = newValue
                }
        }
        .padding()
        .onAppear {
            value = callback.value
        }
    }
}
