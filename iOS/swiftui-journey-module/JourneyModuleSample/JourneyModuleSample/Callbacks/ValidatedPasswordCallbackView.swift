//
//  ValidatedPasswordCallbackView.swift
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
        let errorMessages = callback.failedPolicies.map { $0.failedDescription(for: callback.prompt) }

        PingSecureField(
            label: callback.prompt,
            text: $text,
            isVisible: $passwordVisibility,
            errorMessages: errorMessages,
            onSubmit: onNodeUpdated
        )
        .onAppear { text = callback.password }
        .onChange(of: text) { callback.password = $0 }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}
