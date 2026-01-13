//
//  SecureFieldView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import Combine

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
