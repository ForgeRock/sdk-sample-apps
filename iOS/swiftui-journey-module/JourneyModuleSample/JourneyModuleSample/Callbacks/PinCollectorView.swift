
//
//  PinCollectorView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingBinding
import Combine

struct PinCollectorView: View {
    let prompt: Prompt
    let completion: (String?) -> Void
    
    @State private var pin: String = ""
    @FocusState private var isPinFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text(prompt.title)
                .font(.title)
            Text(prompt.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextField("4-digit PIN", text: $pin)
                .keyboardType(.numberPad)
                .focused($isPinFocused)
                .onChange(of: pin) { newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        pin = String(newValue.prefix(4))
                    }
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .multilineTextAlignment(.center)
                .font(.title2)
            
            HStack {
                Button("Cancel") {
                    completion(nil)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Submit") {
                    completion(pin)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(pin.count != 4)
            }
        }
        .padding()
        .onAppear {
            isPinFocused = true
        }
    }
}
