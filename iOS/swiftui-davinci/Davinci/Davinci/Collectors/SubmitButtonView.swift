// 
//  SubmitButtonView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
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
        VStack(alignment: .leading, spacing: 8) {
            Button {
                field.value = "submit"
                onNext(true)
            } label: {
                Text(field.label)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: 300, height: 50)
                    .background(Color.themeButtonBackground)
                    .cornerRadius(15.0)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
