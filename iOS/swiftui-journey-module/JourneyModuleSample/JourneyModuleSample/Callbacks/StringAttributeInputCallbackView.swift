//
//  StringAttributeInputCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

/**
 * A SwiftUI view for capturing text-based attribute values with validation during authentication flows.
 *
 * This view provides a text field for freeform text input with server-side validation. The field
 * validates against defined policies and displays error messages when validation fails. The border
 * color changes to red when errors are present. Common use cases include email addresses, phone
 * numbers, postal codes, or other validated string attributes.
 *
 * **User Action Required:** YES - User must enter a valid text value.
 *
 * The UI displays a text field with auto-correction disabled, validation feedback, and error
 * messages below the field when validation policies fail. Errors are displayed with descriptive
 * messages from the server.
 */
struct StringAttributeInputCallbackView: View {
    let callback: StringAttributeInputCallback
    let onNodeUpdated: () -> Void

    @State var text: String = ""

    private var hasErrors: Bool {
        !callback.failedPolicies.isEmpty
    }

    var body: some View {
        let errorMessages = callback.failedPolicies.map { $0.failedDescription(for: callback.prompt) }

        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(callback.prompt)
                .pingSectionHeader()

            TextField(callback.prompt, text: $text)
                .pingTextFieldStyle(showsError: hasErrors)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit(onNodeUpdated)

            PingFieldMessages(errorMessages: errorMessages)
        }
        .onAppear { text = callback.value }
        .onChange(of: text) { callback.value = $0 }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}
