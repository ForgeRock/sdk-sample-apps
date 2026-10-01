//
//  PinCollectorView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingBinding

/**
 * A SwiftUI view for collecting a 4-digit PIN during device binding or signing operations.
 *
 * This view displays a PIN entry interface with a numeric keypad, automatically limiting input
 * to exactly 4 digits. The interface includes a title, description from the provided prompt,
 * and action buttons for canceling or submitting the PIN. The PIN field is automatically focused
 * when the view appears for immediate user input.
 *
 * **User Action Required:** YES - User must:
 * 1. Enter a 4-digit PIN using the numeric keypad
 * 2. Tap "Submit" to confirm the PIN, or "Cancel" to abort the operation
 *
 * The UI displays:
 * - Title and description from the Prompt object
 * - Centered text field with numeric keypad, limited to 4 digits
 * - Cancel button (red) - returns nil to indicate cancellation
 * - Submit button (blue) - returns the entered PIN (disabled until 4 digits are entered)
 *
 * This view is typically presented modally by CustomPinCollector when device binding or
 * signing operations require PIN authentication.
 */
struct PinCollectorView: View {
    let prompt: Prompt
    let completion: (String?) -> Void
    
    @State private var pin: String = ""
    @FocusState private var isPinFocused: Bool
    
    var body: some View {
        VStack(spacing: PingTheme.Spacing.large) {
            Text(prompt.title)
                .pingScreenTitle()
            Text(prompt.description)
                .pingSupportingText()

            TextField("4-digit PIN", text: $pin)
                .keyboardType(.numberPad)
                .focused($isPinFocused)
                .onChange(of: pin) { newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        pin = String(newValue.prefix(4))
                    }
                }
                .multilineTextAlignment(.center)
                .font(PingTheme.Typography.sectionTitle)
                .pingTextFieldStyle()

            HStack(spacing: PingTheme.Spacing.small) {
                Button("Cancel") {
                    completion(nil)
                }
                .buttonStyle(.pingDestructive)

                Button("Submit") {
                    completion(pin)
                }
                .buttonStyle(.pingPrimary)
                .disabled(pin.count != 4)
            }
        }
        .padding(PingTheme.Spacing.screen)
        .onAppear {
            isPinFocused = true
        }
    }
}
