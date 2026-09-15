//
//  FidoAuthenticationCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingFido

/**
 * A SwiftUI view for handling FIDO2/WebAuthn authentication during authentication flows.
 *
 * This view initiates passwordless authentication using FIDO2 credentials (passkeys) stored on
 * the device. When the user taps the authentication button, the system prompts for biometric
 * verification (Face ID/Touch ID) or device passcode to authorize the FIDO2 credential usage.
 * This provides strong, phishing-resistant authentication.
 *
 * **User Action Required:** YES - User must:
 * 1. Tap the "Authenticate with FIDO" button
 * 2. Complete biometric authentication (Face ID/Touch ID) or enter device passcode
 *
 * The UI displays a button that triggers the FIDO2 authentication ceremony. The system handles
 * the biometric prompt and credential selection automatically.
 */
struct FidoAuthenticationCallbackView: View {
    var callback: FidoAuthenticationCallback
    let onNext: () -> Void

    @State private var preferImmediatelyAvailableCredentials = false

    var body: some View {
        VStack {
            Text("FIDO Authentication")
                .pingScreenTitle()

            Toggle("Local credentials only", isOn: $preferImmediatelyAvailableCredentials)

            Button(action: {
                Task {
                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                          let window = windowScene.windows.first else {
                        print("Could not find active window scene.")
                        return
                    }

                    let result = await callback.authenticate(
                        window: window,
                        preferImmediatelyAvailableCredentials: preferImmediatelyAvailableCredentials
                    )

                    switch result {
                    case .success(let responseDict):
                        print("FIDO Authentication successful: \(responseDict)")
                        onNext()
                    case .failure(let error):
                        print("FIDO Authentication failed: \(error.localizedDescription)")
                        onNext()
                    }
                }
            }) {
                Text("Authenticate with FIDO")
            }
            .buttonStyle(.pingPrimary)
        }
    }
}
