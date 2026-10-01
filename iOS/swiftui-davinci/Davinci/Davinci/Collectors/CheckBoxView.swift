//
//  CheckBoxView.swift
//  Davinci
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that renders a group of checkbox options for multi-selection.
///
/// The CheckBoxView presents multiple options as checkboxes, allowing users to select
/// multiple values from a list. It provides validation feedback using the ValidationViewModel
/// and reports changes back to the parent through the onNodeUpdated callback.
///
/// Properties:
/// - field: The MultiSelectCollector that contains the options, label, and manages selection state
/// - onNodeUpdated: A callback function that notifies the parent when the field value changes
/// - selectedOptions: State variable that tracks the currently selected options
/// - isValid: State variable that tracks the validation state of the field
///
/// The view updates validation state when the ValidationViewModel triggers validation
/// and when selections change.
struct CheckBoxView: View {
    var field: MultiSelectCollector
    var onNodeUpdated: () -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State private var selectedOptions: [String] = []
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(field.required ? "\(field.label)*" : field.label)
                .pingSectionHeader()
            VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
                ForEach(field.options, id: \.value) { option in
                    let isSelected = selectedOptions.contains(option.value)

                    Button(action: {
                        if isSelected {
                            selectedOptions.removeAll { $0 == option.value }
                            field.value.removeAll { $0 == option.value }
                        } else {
                            selectedOptions.append(option.value)
                            field.value.append(option.value)
                        }
                        isValid = field.validate().isEmpty
                        onNodeUpdated()
                    }) {
                        HStack {
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .foregroundStyle(isSelected ? PingTheme.Color.actionPrimary : PingTheme.Color.contentSecondary)
                            Text(option.label)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, PingTheme.Control.fieldPadding)
            .padding(.vertical, PingTheme.Spacing.compact)
            .pingOutlinedContainerStyle(showsError: !isValid)
            if !isValid {
                PingFieldMessages(errorMessages: field.validate().map { $0.errorMessage }.sorted())
            }
        }
        .padding(.vertical, PingTheme.Spacing.small)
        .onAppear {
            selectedOptions = field.value.sorted()
        }
        .onChange(of: validationViewModel.shouldValidate) { newValue in
            if newValue {
                isValid = field.validate().isEmpty
            }
        }
    }
}
