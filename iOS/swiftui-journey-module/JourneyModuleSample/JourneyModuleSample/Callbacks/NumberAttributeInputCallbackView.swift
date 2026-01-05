//
//  NumberAttributeInputCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney

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
