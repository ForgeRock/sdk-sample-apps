//
//  DeviceBindingCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingBinding

/**
 * A SwiftUI view for handling device binding operations during authentication flows.
 *
 * This view automatically initiates the device binding process when displayed, which securely
 * associates the current device with the user's account. The binding may involve biometric
 * authentication or PIN collection depending on configuration. Once binding completes,
 * the view automatically proceeds to the next step.
 *
 * **User Action Required:** CONDITIONAL - May require biometric authentication or PIN entry
 * depending on the device authenticator configuration. Default configuration binds automatically.
 *
 * The UI displays a loading indicator with status message during the binding process. The component
 * supports custom PIN collectors and biometric authenticators through configuration options.
 */
struct DeviceBindingCallbackView: View {
    var callback: DeviceBindingCallback
    let onNext: () -> Void
    
    var body: some View {
        VStack {
            Text("Device Binding")
                .font(.title)
            Text("Please wait while we bind your device.")
                .font(.body)
                .padding()
            ProgressView()
        }
        .onAppear(perform: handleDeviceBinding)
    }
    
    private func handleDeviceBinding() {
        Task {
            /*
             For using a custom view for PIN collection, you can provide a CustomPinCollector
             through the configuration as shown below:
             
            let result = await callback.bind { config in
                config.pinCollector = CustomPinCollector()
            }
             
             For more advanced configuration, you can create a custom AppPinConfig:
             
            let result = await callback.bind { config in
                let appPinConfig = AppPinConfig(
                    prompt: Prompt(title: "Enter PIN", subtitle: "Security", description: "Enter your 4-digit PIN"),
                    pinRetry: 5,
                    pinCollector: CustomPinCollector()
                )
                config.deviceAuthenticator = AppPinAuthenticator(config: appPinConfig)
            }
             
             For biometric authenticators, you can also use BiometricAuthenticatorConfig:
             
            let result = await callback.bind { config in
                let biometricConfig = BiometricAuthenticatorConfig(
                    keyTag: "my-custom-biometric-key"
                )
                
                // Set the authenticator config - the appropriate authenticator will be used based on callback type
                config.authenticatorConfig = biometricConfig
            }
             
             You can also configure with a logger for debugging:
             
            let result = await callback.bind { config in
                // Create a custom logger instance
                let customLogger = Logger.logger // or your custom logger implementation
                
                let biometricConfig = BiometricAuthenticatorConfig(
                    logger: customLogger,
                    keyTag: "secure-biometric-key-\(callback.userId)"
                )
                
                config.authenticatorConfig = biometricConfig
            }
             */
            let result = await callback.bind()
            switch result {
            case .success(let json):
                print("Device binding success: \(json)")
            case .failure(let error):
                if let deviceBindingStatus = error as? DeviceBindingStatus {
                    print("Device binding failed: \(deviceBindingStatus.errorMessage)")
                } else {
                    print("Device binding failed: \(error.localizedDescription)")
                }
            }
            onNext()
        }
    }
}

