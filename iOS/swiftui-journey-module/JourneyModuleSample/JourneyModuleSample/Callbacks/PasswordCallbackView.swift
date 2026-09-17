// 
//  PasswordCallbackView.swift
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
 * A SwiftUI view for capturing password input during authentication flows.
 *
 * This view provides a secure password input field with visibility toggle functionality.
 * The password is masked by default but can be revealed using the visibility toggle.
 * The input is submitted when the user presses return or completes editing.
 *
 * **User Action Required:** YES - User must enter their password in the secure field.
 *
 * The UI displays a SecureFieldView component with password visibility toggle.
 * The field updates the callback's internal state on each keystroke and commits
 * to the journey node when submitted.
 */
struct PasswordCallbackView: View {

    var callback: PasswordCallback
    var onNodeUpdated: () -> Void

    @State var text: String = ""
    @State private var passwordVisibility: Bool = false

    var body: some View {
        PingSecureField(
            label: callback.prompt,
            text: $text,
            isVisible: $passwordVisibility,
            onSubmit: onNodeUpdated
        )
        .onAppear { text = callback.password }
        .onChange(of: text) { callback.password = $0 }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}

