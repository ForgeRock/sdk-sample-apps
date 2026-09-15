//
//  ChoiceCallbackView.swift
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
 * A SwiftUI view for presenting multiple choice selections during authentication flows.
 *
 * This view displays a picker menu with predefined choices from which the user must select.
 * The selected choice index is tracked and updated in the callback as the user makes their
 * selection. Common use cases include selecting authentication methods, security questions,
 * or other configuration options.
 *
 * **User Action Required:** YES - User must select one option from the available choices.
 *
 * The UI displays a menu-style picker with a rounded border. The picker is pre-populated
 * with the current selection and updates the callback immediately when changed.
 */
struct ChoiceCallbackView: View {
    let callback: ChoiceCallback
    let onNodeUpdated: () -> Void

    @State var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Picker(callback.prompt, selection: $selectedIndex) {
                ForEach(callback.choices.indices, id: \.self) { index in
                    Text(callback.choices[index]).tag(index)
                }
            }
            .pickerStyle(.menu)
            .pingTextFieldStyle()
            .onChange(of: selectedIndex) { newValue in
                callback.selectedIndex = newValue
            }
        }
        .padding(.vertical, PingTheme.Spacing.small)
        .onAppear {
            selectedIndex = callback.selectedIndex
        }
    }
}
