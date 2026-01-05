//
//  FidoRegistrationCallbackView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingFido

struct FidoRegistrationCallbackView: View {
    var callback: FidoRegistrationCallback
    let onNext: () -> Void
    
    @State private var deviceName: String = ""
    
    var body: some View {
        VStack {
            Text("FIDO Registration")
                .font(.title)
            TextField("Device Name (Optional)", text: $deviceName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 1. Button action still creates a Task
            Button(action: {
                Task {
                    // 2. Get the window
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        print("Could not find active window scene.")
                        // Consider how to handle this UI-wise, maybe disable the button or show an alert
                        return // Exit if no window found
                    }
                    
                    // 3. Call the async function and await its Result
                    //    We pass nil if the deviceName is empty, otherwise pass the name
                    let name = deviceName.isEmpty ? nil : deviceName
                    let result = await callback.register(deviceName: name, window: window)
                    
                    // 4. Handle the Result
                    switch result {
                    case .success(let responseDict):
                        // Optional: Use responseDict if needed
                        print("FIDO Registration successful: \(responseDict)")
                        // Call onNext on success
                        onNext()
                    case .failure(let error):
                        // Handle errors
                        print("FIDO Registration failed: \(error.localizedDescription)")
                        // Optionally: show an alert to the user here
                        onNext()
                    }
                }
            }) {
                Text("Register with FIDO")
            }
        }
    }
}
