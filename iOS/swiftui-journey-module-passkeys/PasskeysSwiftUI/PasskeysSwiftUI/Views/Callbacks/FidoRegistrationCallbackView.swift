//
//  FidoRegistrationCallbackView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingFido

struct FidoRegistrationCallbackView: View {
    let callback: FidoRegistrationCallback
    let onNext: () -> Void

    @State private var deviceName = UIDevice.current.name
    @State private var errorMessage: String?
    @State private var isRegistering = false

    var body: some View {
        VStack(spacing: 20) {
            FidoIconView(systemName: "faceid", tint: .pingRed)

            VStack(spacing: 6) {
                Text("Register Passkey")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Create a passkey for fast, secure biometric login.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            PingTextField(placeholder: "Device Name", text: $deviceName)

            if let errorMessage {
                ErrorMessageView(message: errorMessage)
            }

            Button(action: register) {
                if isRegistering {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Register with Passkey")
                }
            }
            .buttonStyle(PingPrimaryButtonStyle())
            .disabled(isRegistering)
        }
    }

    private func register() {
        Task {
            isRegistering = true
            defer { isRegistering = false }

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                errorMessage = "Unable to find active window."
                return
            }

            let name = deviceName.isEmpty ? nil : deviceName
            let result = await callback.register(deviceName: name, window: window)

            switch result {
            case .success:
                onNext()
            case .failure(let error):
                errorMessage = error.localizedDescription
                onNext()
            }
        }
    }
}
