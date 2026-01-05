import SwiftUI
import PingBinding

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

