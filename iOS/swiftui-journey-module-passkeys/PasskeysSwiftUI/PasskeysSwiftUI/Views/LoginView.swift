//
//  LoginView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import PingOrchestrate

struct LoginView: View {
    let continueNode: ContinueNode?
    let isLoading: Bool
    let onNext: () -> Void

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    PingHeaderView()

                    VStack(spacing: 24) {
                        if let continueNode {
                            ContinueNodeView(node: continueNode, onNext: onNext)
                        } else {
                            SignInPromptView(onSignIn: onNext)
                        }
                    }
                    .padding(24)
                }
            }

            if isLoading {
                LoadingOverlay("Signing in…")
            }
        }
    }
}

// MARK: - Sign In Prompt

private struct SignInPromptView: View {
    let onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome back")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Sign in with your credentials or use a passkey for biometric authentication.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Sign In", action: onSignIn)
                .buttonStyle(PingPrimaryButtonStyle())
        }
    }
}
