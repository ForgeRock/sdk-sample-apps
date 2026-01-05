
//
//  PinCollectorView.swift
//  PingExample
//
//  Created by GP on 30/10/2025.
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
