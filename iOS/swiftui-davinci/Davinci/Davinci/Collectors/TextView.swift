//
//  TextView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity. All rights reserved.
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
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                TextField(
                    field.required ? "\(field.label)*" : field.label,
                    text: $text
                )
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isValid ? Color.gray : Color.red, lineWidth: 1)
                )
                .onAppear(perform: {
                    text = field.value
                })
                .onChange(of: text) { newValue in
                    field.value = newValue
                    isValid = field.validate().isEmpty
                    onNodeUpdated()
                }
                if !isValid {
                    ErrorMessageView(errors: field.validate().map { $0.errorMessage }.sorted())
                }
            }
        }
        .onChange(of: validationViewModel.shouldValidate) { newValue in
            if newValue {
                isValid = field.validate().isEmpty
            }
        }
        .padding()
    }
}
