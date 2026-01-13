//
//  ConfirmationCallbackView.swift
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
 * A SwiftUI view for presenting confirmation dialogs with multiple action buttons.
 *
 * This view displays a prompt message along with action buttons for the user to confirm
 * or respond to a decision. Common use cases include "Yes/No" confirmations, "OK/Cancel"
 * dialogs, or multi-option confirmations. When the user selects an option, the callback
 * records the selection and immediately proceeds to the next step.
 *
 * **User Action Required:** YES - User must click one of the provided action buttons.
 *
 * The UI displays an optional prompt message followed by horizontally arranged buttons,
 * right-aligned. Each button is styled with bordered prominent style for clear visibility.
 */
struct ConfirmationCallbackView: View {
    let callback: ConfirmationCallback
    let onSelected: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Display prompt if available
            if !callback.prompt.isEmpty {
                Text(callback.prompt)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }

            // Buttons arranged horizontally, trailing-aligned
            HStack {
                Spacer()

                ForEach(callback.options.indices, id: \.self) { index in
                    Button(callback.options[index]) {
                        callback.selectedIndex = index
                        onSelected()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
    }
}
