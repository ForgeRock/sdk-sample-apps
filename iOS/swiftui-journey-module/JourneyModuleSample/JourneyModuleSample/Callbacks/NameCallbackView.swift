// 
//  NameCallbackView.swift
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
                    .stroke(Color.gray, lineWidth: 1)
            )
            .onAppear(perform: {
                text = callback.name
            })
            .onChange(of: text) { newValue in
                callback.name = newValue // update internal state only
            }
            .onSubmit {
                onNodeUpdated() // commit to node state only when done
            }
            .padding()
        }
    }
}
