//
//  FidoAuthenticationCallbackView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingFido

struct FidoAuthenticationCallbackView: View {
    let callback: FidoAuthenticationCallback
    let onNext: () -> Void

    @State private var errorMessage: String?
    @State private var isAuthenticating = false

    var body: some View {
        VStack(spacing: 20) {
            FidoIconView(systemName: "touchid", tint: .pingRed)

            VStack(spacing: 6) {
                Text("Biometric Authentication")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Use your passkey to sign in securely.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let errorMessage {
                ErrorMessageView(message: errorMessage)
            }

            Button(action: authenticate) {
                if isAuthenticating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Authenticate with Passkey")
                }
            }
            .buttonStyle(PingPrimaryButtonStyle())
            .disabled(isAuthenticating)
        }
    }

    private func authenticate() {
        Task {
            isAuthenticating = true
            defer { isAuthenticating = false }

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                errorMessage = "Unable to find active window."
                return
            }

            let result = await callback.authenticate(window: window)

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
