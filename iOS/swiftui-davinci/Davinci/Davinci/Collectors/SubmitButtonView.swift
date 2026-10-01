// 
//  SubmitButtonView.swift
//  Davinci
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that creates a form submission button.
///
/// The SubmitButtonView creates a styled button for submitting form data.
/// When pressed, it sets the field's value to "submit" and triggers navigation
/// to the next step in the flow.
///
/// Properties:
/// - field: The SubmitCollector that manages the button state
/// - onNext: A callback function that navigates to the next step when the button is pressed
///
/// The view uses the Ping Identity theme styling for the button appearance.
struct SubmitButtonView: View {
    var field: SubmitCollector
    let onNext: (Bool) -> Void
    
    var body: some View {
        Button(field.label) {
            field.value = "submit"
            onNext(true)
        }
        .buttonStyle(.pingPrimary)
        .padding(.vertical, PingTheme.Spacing.small)
        .onDisappear {
            field.value = ""
        }
    }
        
}
