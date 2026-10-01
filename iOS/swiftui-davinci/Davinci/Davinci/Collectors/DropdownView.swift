//
//  DropdownView.swift
//  Davinci
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that presents a dropdown menu with single-selection capabilities.
///
/// The DropdownView provides a compact menu interface for selecting a single option
/// from a list. It manages selection state and validation, presenting error messages
/// when validation fails.
///
/// Properties:
/// - field: The SingleSelectCollector containing options, label, and selection state
/// - onNodeUpdated: A callback function that notifies the parent when the field value changes
/// - expanded: State variable that tracks whether the dropdown is expanded
/// - selectedOption: State variable that tracks the currently selected option
/// - isValid: State variable that tracks the validation state of the field
///
/// The view updates the selection and performs validation when an option is selected.
struct DropdownView: View {
    var field: SingleSelectCollector
    var onNodeUpdated: () -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State private var expanded: Bool = false
    @State private var selectedOption: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(field.required ? "\(field.label)*" : field.label)
                .pingSectionHeader()
            Menu {
                ForEach(field.options, id: \.value) { option in
                    Button(action: {
                        selectedOption = option.value
                        field.value = option.value
                        expanded = false
                        isValid = field.validate().isEmpty
                        onNodeUpdated()
                    }) {
                        Text(option.label)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                }
            } label: {
                HStack {
                    Text(selectedOption.isEmpty ? "Select an option" : selectedOption)
                        .foregroundStyle(selectedOption.isEmpty ? PingTheme.Color.contentSecondary : PingTheme.Color.contentPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle(degrees: expanded ? 180 : 0))
                        .foregroundStyle(PingTheme.Color.actionPrimary)
                }
                .frame(maxWidth: .infinity)
                .pingTextFieldStyle(showsError: !isValid)
            }
            if !isValid {
                PingFieldMessages(errorMessages: field.validate().map { $0.errorMessage }.sorted())
            }
        }
        .padding(.vertical, PingTheme.Spacing.small)
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
