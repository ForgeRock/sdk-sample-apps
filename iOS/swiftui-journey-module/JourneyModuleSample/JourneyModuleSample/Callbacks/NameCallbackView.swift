// 
//  NameCallbackView.swift
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
 * A SwiftUI view for capturing username or name input during authentication flows.
 *
 * This view prompts the user to enter their name or username in a text field. The input is
 * validated and submitted when the user presses return or completes editing. The callback
 * updates its internal state as the user types, but only commits to the journey node when
 * the input is submitted.
 *
 * **User Action Required:** YES - User must enter their name/username in the text field.
 *
 * The UI displays a text field with auto-correction disabled and no capitalization. The field
 * is styled with a rounded border and updates the callback's internal state on each keystroke.
 */
struct NameCallbackView: View {
    let callback: NameCallback
    let onNodeUpdated: () -> Void

    @State var text: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(callback.prompt)
                .pingSectionHeader()

            TextField(callback.prompt, text: $text)
                .pingTextFieldStyle()
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit(onNodeUpdated)
        }
        .onAppear { text = callback.name }
        .onChange(of: text) { callback.name = $0 }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}
