//
//  TextView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct TextView: View {
    let field: TextCollector
    let onNodeUpdated: () -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State var text: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        let errorMessages = isValid ? [] : field.validate().map(\.errorMessage).sorted()

        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(field.required ? "\(field.label)*" : field.label)
                .pingSectionHeader()

            TextField(field.label, text: $text)
                .pingTextFieldStyle(showsError: !errorMessages.isEmpty)

            PingFieldMessages(errorMessages: errorMessages)
        }
        .onAppear { text = field.value }
        .onChange(of: text) { newValue in
            field.value = newValue
            isValid = field.validate().isEmpty
            onNodeUpdated()
        }
        .onChange(of: validationViewModel.shouldValidate) { newValue in
            if newValue {
                isValid = field.validate().isEmpty
            }
        }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}
