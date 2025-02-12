// 
//  RadioButtonView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity. All rights reserved.
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
