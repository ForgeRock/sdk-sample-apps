//
//  ValidatedUsernameCallbackView.swift
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
 * A SwiftUI view for capturing username input with server-side validation during authentication flows.
 *
 * This view provides a text field for username input with real-time validation against server-defined
 * policies. The field validates username format, availability, and other requirements, displaying
 * error messages when validation fails. The border color changes to red when errors are present.
 * Commonly used during user registration.
 *
 * **User Action Required:** YES - User must enter a valid username that meets all requirements.
 *
 * The UI displays a text field with auto-correction disabled, validation feedback, and error
 * messages below the field when validation policies fail (e.g., username taken, invalid format).
 */
struct ValidatedUsernameCallbackView: View {
    let callback: ValidatedUsernameCallback
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
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(hasErrors ? Color.red : Color.gray, lineWidth: 1)
            )
            .onAppear(perform: {
                text = callback.username
            })
            .onChange(of: text) { newValue in
                callback.username = newValue
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
