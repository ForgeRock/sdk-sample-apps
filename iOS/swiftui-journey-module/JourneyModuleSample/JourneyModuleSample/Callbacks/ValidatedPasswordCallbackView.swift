//
//  ValidatedPasswordCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import Combine

/**
 * A SwiftUI view for capturing password input with server-side validation during authentication flows.
 *
 * This view provides a secure password input field with visibility toggle and real-time validation
 * against server-defined password policies. The field displays error messages when the password
 * fails to meet requirements (e.g., minimum length, complexity, character types). Commonly used
 * during registration or password change flows.
 *
 * **User Action Required:** YES - User must enter a password that meets validation requirements.
 *
 * The UI displays a SecureFieldView with password visibility toggle, validation feedback, and
 * error messages when policies fail. The field appearance changes to indicate error states.
 */
struct ValidatedPasswordCallbackView: View {
    let callback: ValidatedPasswordCallback
    let onNodeUpdated: () -> Void

    @State var text: String = ""
    @State private var passwordVisibility: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Password Input Field
            VStack(alignment: .leading) {
                SecureFieldView(
                    label: callback.prompt,
                    value: $text,
                    isPasswordVisible: $passwordVisibility,
                    onValueChange: { value in
                        callback.password = value
                    },
                    onAppear: {
                        text = callback.password
                    },
                    isError: !callback.failedPolicies.isEmpty,
                    errorMessages: callback.failedPolicies.isEmpty ? [] : callback.failedPolicies.map({ $0.failedDescription(for: callback.prompt)})
                )
                .onSubmit {
                    onNodeUpdated()
                }
            }
        }
        .padding()
    }
}
