// 
//  PasswordView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view that handles password input with optional verification.
///
/// The PasswordView creates a secure text field for password entry, with an option
/// to toggle visibility. For password verification (when field.type is "PASSWORD_VERIFY"),
/// it adds a second field to confirm the password matches.
///
/// Properties:
/// - field: The PasswordCollector that manages the password state and validation
/// - onNodeUpdated: A callback function that notifies the parent when the field value changes
/// - text: State variable for the password text
/// - isValid: State variable that tracks the validation state of the field
/// - verify: State variable for the verification password (when needed)
/// - passwordVisibility: State variable that tracks whether the password is visible
/// - verifyPasswordVisibility: State variable that tracks whether the verification password is visible
///
/// The view performs validation on both the password requirements and matching when verification is used.
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
        VStack(alignment: .leading, spacing: 16) {
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
        .padding()
    }
}

/// A SwiftUI component that creates a password field with visibility toggle.
///
/// The SecureFieldView provides a reusable component for password entry, including
/// the ability to toggle between secure and plain text visibility.
///
/// Properties:
/// - label: The text label for the field
/// - value: Binding to the password text value
/// - isPasswordVisible: Binding to control password visibility
/// - onValueChange: Callback function for when the password value changes
/// - onAppear: Callback function for when the view appears
/// - isError: Boolean indicating if the field has a validation error
/// - errorMessages: Array of error messages to display
///
/// The view toggles between SecureField and TextField based on the visibility state.
struct SecureFieldView: View {
    let label: String
    @Binding var value: String
    @Binding var isPasswordVisible: Bool
    var onValueChange: (String) -> Void
    var onAppear: () -> Void
    var isError: Bool
    var errorMessages: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if isPasswordVisible {
                    TextField(label, text: $value)
                } else {
                    SecureField(label, text: $value)
                }
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundStyle(Color.themeButtonBackground)
                        .frame(width: 20, height: 20)
                }
            }
            .onAppear(perform: onAppear)
            .onChange(of: value) { newValue in
                onValueChange(value)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isError ? Color.red : Color.gray, lineWidth: 1)
            )
            .textInputAutocapitalization(.never)
            
            if isError {
                ErrorMessageView(errors: errorMessages)
            }
        }
    }
}
