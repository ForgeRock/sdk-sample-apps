//
//  ErrorView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci
import PingOrchestrate

/// A view for displaying error messages.
/// - Provides a consistent UI for error presentation across the application.
struct ErrorView: View {
    /// The error message to display to the user.
    let message: String
    
    var body: some View {
        HStack {
            /// Warning triangle icon to visually indicate an error
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.red)
                .padding(.trailing, 8)
            /// The error message text
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.red)
            Spacer()
        }
        .padding()
        .background(
            /// Rounded background with subtle shadow for visual emphasis
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .gray, radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
    }
}

/// A view for displaying detailed error information from an ErrorNode.
/// - Provides both a summary view and detailed information via an alert.
struct ErrorNodeView: View {
    /// The error node containing detailed error information.
    let node: ErrorNode
    /// State to control whether detailed error information is shown.
    @State private var showDetails: Bool = false
    
    /// Formats the error details for display in the alert.
    /// - Extracts error messages and inner error details from the node.
    private var errorText: String {
        var error = ""
        
        for detail in node.details {
            if let details = detail.rawResponse.details {
                for detail in details {
                    error += "\(String(describing: detail.message))\n\n"
                    
                    if let innerError = detail.innerError {
                        for (key, value) in innerError.errors {
                            error += "\(key): \(value)\n\n"
                        }
                    }
                }
                
            }
        }
        
        return error
    }
    
    var body: some View {
        /// Uses the standard ErrorView for consistent UI presentation
        ErrorView(message: node.message)
            .onTapGesture {
                /// Shows detailed error information when tapped
                showDetails = true
            }
            .alert("Error Details", isPresented: $showDetails) {
                Button("OK") {
                    showDetails = false
                }
            } message: {
                Text(errorText)
            }
    }
}
