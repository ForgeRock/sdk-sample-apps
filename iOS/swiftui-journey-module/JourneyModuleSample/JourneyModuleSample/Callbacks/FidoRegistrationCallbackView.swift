//
//  FidoRegistrationCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingFido

/**
 * A SwiftUI view for handling FIDO2/WebAuthn credential registration during authentication flows.
 *
 * This view enables users to register a new FIDO2 credential (passkey) on their device for
 * passwordless authentication. Users can optionally provide a device name for identification.
 * When the user taps the registration button, the system prompts for biometric verification
 * (Face ID/Touch ID) or device passcode to create and secure the new credential.
 *
 * **User Action Required:** YES - User must:
 * 1. Optionally enter a device name
 * 2. Tap the "Register with FIDO" button
 * 3. Complete biometric authentication (Face ID/Touch ID) or enter device passcode
 *
 * The UI displays a text field for optional device naming and a button to initiate registration.
 * The system handles the biometric prompt and credential creation automatically.
 */
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
