// 
//  RadioButtonView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct RadioButtonView: View {
    var field: SingleSelectCollector
    var onNodeUpdated: () -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State private var selectedOption: String = ""
    @State private var isValid: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(field.required ? "\(field.label)*" : field.label)
                .pingSectionHeader()
            VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
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
                                    .stroke(selectedOption == option.value ? PingTheme.Color.actionPrimary : PingTheme.Color.contentSecondary, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .fill(selectedOption == option.value ? PingTheme.Color.actionPrimary : Color.clear)
                                            .frame(width: 12, height: 12)
                                    )
                                Text(option.label)
                                    .foregroundStyle(PingTheme.Color.contentPrimary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, PingTheme.Spacing.xSmall)
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
            selectedOption = field.value
        }
        .onChange(of: validationViewModel.shouldValidate) { newValue in
            if newValue {
                isValid = field.validate().isEmpty
            }
        }
    }
}
