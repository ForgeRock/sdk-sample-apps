//
//  FidoAuthenticationCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingFido
import Combine

struct FidoAuthenticationCallbackView: View {
    var callback: FidoAuthenticationCallback
    let onNext: () -> Void
    
    var body: some View {
        VStack {
            Text("FIDO Authentication")
                .font(.title)
            
            // 1. Button action still creates a Task
            Button(action: {
                Task {
                    // 2. Get the window
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        print("Could not find active window scene.")
                        // Consider how to handle this UI-wise
                        return // Exit if no window found
                    }
                    
                    // 3. Call the async function and await its Result
                    let result = await callback.authenticate(window: window)
                    
                    // 4. Handle the Result
                    switch result {
                    case .success(let responseDict):
                        // Optional: Use responseDict if needed
                        print("FIDO Authentication successful: \(responseDict)")
                        // Call onNext success
                        onNext()
                    case .failure(let error):
                        // Handle errors
                        print("FIDO Authentication failed: \(error.localizedDescription)")
                        onNext()
                    }
                }
            }) {
                Text("Authenticate with FIDO")
            }
        }
    }
}
