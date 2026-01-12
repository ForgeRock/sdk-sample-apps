//
//  NumberAttributeInputCallbackView.swift
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
 * A SwiftUI view for capturing numeric attribute values with validation during authentication flows.
 *
 * This view provides a text field configured for decimal number input with real-time validation.
 * Input is filtered to allow only numeric characters and decimal points. The field validates
 * against server-defined policies and displays error messages when validation fails. The border
 * color changes to red when errors are present.
 *
 * **User Action Required:** YES - User must enter a valid numeric value.
 *
 * The UI displays a text field with decimal pad keyboard, validation feedback, and error messages
 * below the field when validation policies fail. Common use cases include age, quantity, or
 * other numeric profile attributes.
 */
struct NumberAttributeInputCallbackView: View {
    let callback: NumberAttributeInputCallback
    let onNodeUpdated: () -> Void

    @State var text: String = ""

    private var hasErrors: Bool {
        !callback.failedPolicies.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                callback.prompt,
                text: $text
            )
            .keyboardType(.decimalPad)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(hasErrors ? Color.red : Color.gray, lineWidth: 1)
            )
            .onAppear(perform: {
                text = String(callback.value)
            })
            .onChange(of: text) { newValue in
                // Validate that input contains only digits and decimal points
                let filtered = newValue.filter { $0.isNumber || $0 == "." }
                if filtered != newValue {
                    text = filtered
                }

                // Update field value if valid number
                if !text.isEmpty, let doubleValue = Double(text) {
                    callback.value = doubleValue
                }
            }
            .onSubmit {
                onNodeUpdated()
            }

            // Error message display
            if hasErrors {
                ErrorMessageView(errors: callback.failedPolicies.map({ $0.failedDescription(for: callback.prompt)}))
            }
        }
        .padding()
    }
}
