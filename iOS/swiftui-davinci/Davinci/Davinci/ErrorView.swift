//
//  ErrorView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci
import PingOrchestrate

/// A view for displaying error messages.
struct ErrorView: View {
    let message: String
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.red)
                .padding(.trailing, 8)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Color.red)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .gray, radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
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
        ErrorView(message: node.message)
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
