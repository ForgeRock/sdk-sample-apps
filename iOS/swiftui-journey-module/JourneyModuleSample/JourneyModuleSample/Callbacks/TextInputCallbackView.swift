//
//  TextInputCallbackView.swift
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
 * A SwiftUI view for capturing general text input during authentication flows.
 *
 * This view provides a basic text field for freeform text input without validation. It is used
 * for capturing various text-based information such as display names, comments, or other
 * non-validated string data. The input updates the callback's internal state on each keystroke
 * and commits to the journey node when submitted.
 *
 * **User Action Required:** YES - User must enter text in the field.
 *
 * The UI displays a text field with auto-correction disabled and no capitalization, styled
 * with a rounded border. The field is pre-populated with any existing value from the callback.
 */
struct TextInputCallbackView: View {
    let callback: TextInputCallback
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
        .onAppear { text = callback.text }
        .onChange(of: text) { callback.text = $0 }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}
