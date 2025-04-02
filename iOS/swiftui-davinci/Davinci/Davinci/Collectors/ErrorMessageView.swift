// 
//  ErrorMessageView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci

/// A SwiftUI view component that displays validation error messages.
///
/// The ErrorMessageView renders a list of error messages in red text to provide
/// feedback about validation failures to the user. It's used by various form
/// components to display validation errors.
///
/// Properties:
/// - errors: An array of error message strings to display
///
/// If the errors array is empty, the view renders an EmptyView to take up no space.
struct ErrorMessageView: View {
    var errors: [String]
    
    var body: some View {
        if errors.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(errors, id: \.self) { error in
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                }
            }
            .padding(2)
        }
    }
}
