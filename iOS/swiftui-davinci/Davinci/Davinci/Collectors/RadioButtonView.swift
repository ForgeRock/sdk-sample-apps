// 
//  RadioButtonView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that presents radio button options for single-selection.
///
/// The RadioButtonView presents a group of radio buttons, allowing users to select
/// exactly one option from a list. It manages selection state and validation,
/// displaying error messages when validation fails.
///
/// Properties:
/// - field: The SingleSelectCollector containing options, label, and selection state
/// - onNodeUpdated: A callback function that notifies the parent when the field value changes
/// - selectedOption: State variable that tracks the currently selected option
/// - isValid: State variable that tracks the validation state of the field
///
/// The view updates validation state when ValidationViewModel triggers validation
/// and when a new selection is made.
struct RadioButtonView: View {
    var field: SingleSelectCollector
    var onNodeUpdated: () -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State private var selectedOption: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(field.required ? "\(field.label)*" : field.label)
                .font(.headline)
                .padding(.bottom, 4)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(field.options, id: \.value) { option in
                    HStack {
                        Button(action: {
                            selectedOption = option.value
                            field.value = option.value
                            isValid = field.validate().isEmpty
                            onNodeUpdated()
                        }) {
                            HStack {
                                Circle()
                                    .stroke(selectedOption == option.value ? Color.themeButtonBackground : Color.gray, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .fill(selectedOption == option.value ? Color.themeButtonBackground : Color.clear)
                                            .frame(width: 12, height: 12)
                                    )
                                Text(option.label)
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isValid ? Color.gray : Color.red, lineWidth: 1)
            )
            if !isValid {
                ErrorMessageView(errors: field.validate().map { $0.errorMessage }.sorted())
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            selectedOption = field.value
        }
        .onChange(of: validationViewModel.shouldValidate) { newValue in
            if newValue {
                isValid = field.validate().isEmpty
            }
        }
    }
}
