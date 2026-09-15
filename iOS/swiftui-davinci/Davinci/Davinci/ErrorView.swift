//
//  ErrorView.swift
//  PingExample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci
import PingOrchestrate

/// A reusable error card view with a title and message in the semantic error color.
struct ErrorView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Text(title)
                .font(PingTheme.Typography.body.weight(.semibold))
                .foregroundStyle(PingTheme.Color.statusError)
            Text(message)
                .font(PingTheme.Typography.supporting)
                .foregroundStyle(PingTheme.Color.statusError)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pingStatusCardStyle(tint: PingTheme.Color.statusError)
        .padding(.horizontal, PingTheme.Spacing.screen)
    }
}


struct ErrorNodeView: View {
    let node: ErrorNode
    @State private var showDetails: Bool = false
    
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
        ErrorView(title: "Error", message: node.message)
            .onTapGesture {
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
