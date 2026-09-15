// 
//  PasswordView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

struct PasswordView: View {
    var field: PasswordCollector
    var onNodeUpdated: () -> Void
    
    @EnvironmentObject var validationViewModel: ValidationViewModel
    @State private var text: String = ""
    @State private var isValid: Bool = true
    @State private var verify: String = ""
    @State private var passwordVisibility: Bool = false
    @State private var verifyPasswordVisibility: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            // Password Input Field
            VStack(alignment: .leading) {
                SecureFieldView(
                    label: field.required ? "\(field.label)*" : field.label,
                    value: $text,
                    isPasswordVisible: $passwordVisibility,
                    onValueChange: { value in
                        field.value = value
                        isValid = field.validate().isEmpty
                        onNodeUpdated()
                    }, onAppear: {
                        text = field.value
                    },
                    isError: !isValid,
                    errorMessages: field.validate().map { $0.errorMessage }.sorted()
                )
            }
            .onChange(of: validationViewModel.shouldValidate) { newValue in
                if newValue {
                    isValid = field.validate().isEmpty
                }
            }
            
            // Password Policy Requirements
            if let policy = field.passwordPolicy() {
                PasswordRequirementsView(policy: policy, password: text)
            }
            
            // Password Verification Field
            if field.type == "PASSWORD_VERIFY" {
                SecureFieldView(
                    label: "Verify Password*",
                    value: $verify,
                    isPasswordVisible: $verifyPasswordVisibility,
                    onValueChange: { value in
                        verify = value
                    },
                    onAppear: {},
                    isError: verify != field.value,
                    errorMessages: verify != field.value ? ["Password does not match"] : [""]
                )
            }
        }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}

struct SecureFieldView: View {
    let label: String
    @Binding var value: String
    @Binding var isPasswordVisible: Bool
    var onValueChange: (String) -> Void
    var onAppear: () -> Void
    var isError: Bool
    var errorMessages: [String]

    private var displayedErrorMessages: [String] {
        isError ? errorMessages.filter { !$0.isEmpty } : []
    }

    var body: some View {
        PingSecureField(
            label: label,
            text: $value,
            isVisible: $isPasswordVisible,
            errorMessages: displayedErrorMessages
        )
        .onAppear(perform: onAppear)
        .onChange(of: value) { onValueChange($0) }
    }
}
