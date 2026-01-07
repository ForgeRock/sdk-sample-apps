//
//  DeviceSigningVerifierCallbackView.swift
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

struct DeviceSigningVerifierCallbackView: View {
    var callback: DeviceSigningVerifierCallback
    let onNext: () -> Void
    
    var body: some View {
        VStack {
            Text("Device Signing")
                .font(.title)
            Text("Please wait while we sign the challenge.")
                .font(.body)
                .padding()
            ProgressView()
        }
        .onAppear(perform: handleDeviceSigning)
    }
    
    private func handleDeviceSigning() {
        Task {
            /*
            For using a custom view for PIN collection, you can provide a CustomPinCollector
            through the configuration as shown below:
            
            let result = await callback.sign { config in
                config.pinCollector = CustomPinCollector()
            }
             
             For more advanced configuration with retry logic and custom prompts:
             
            let result = await callback.sign { config in
                let appPinConfig = AppPinConfig(
                    prompt: Prompt(title: "Verify Identity", subtitle: "Sign Transaction", description: "Enter your PIN to sign"),
                    pinRetry: 3,
                    pinCollector: CustomPinCollector()
                )
                config.deviceAuthenticator = AppPinAuthenticator(config: appPinConfig)
            }
             
             For biometric authenticators during signing, you can also use BiometricAuthenticatorConfig:
             
            let result = await callback.sign { config in
                let biometricConfig = BiometricAuthenticatorConfig(
                    keyTag: "my-custom-signing-key"
                )
                
                // Set the authenticator config - the appropriate authenticator will be used based on callback type
                config.authenticatorConfig = biometricConfig
            }
             
             You can also configure with a logger for monitoring signing operations:
             
            let result = await callback.sign { config in
                let customLogger = Logger.logger // or your custom logger implementation
                
                let biometricConfig = BiometricAuthenticatorConfig(
                    logger: customLogger,
                    keyTag: "signing-key-\(callback.userId ?? "default")"
                )
                
                config.authenticatorConfig = biometricConfig
            }
             
             For custom user key selection when multiple keys are available:
             
            let result = await callback.sign { config in
                // Use a custom UI for selecting from multiple device keys
                config.userKeySelector = CustomUserKeySelector()
            }
             */
            let result = await callback.sign()
            switch result {
            case .success(let json):
                print("Device signing success: \(json)")
            case .failure(let error):
                if let deviceBindingStatus = error as? DeviceBindingStatus {
                    print("Device signing failed: \(deviceBindingStatus.errorMessage)")
                } else {
                    print("Device signing failed: \(error.localizedDescription)")
                }
            }
            onNext()
        }
    }
}

