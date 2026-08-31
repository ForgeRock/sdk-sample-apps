//
//  ContentView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOrchestrate
import PingJourney

struct ContentView: View {
    @State private var loginViewModel = LoginViewModel()

    var body: some View {
        Group {
            switch loginViewModel.node {
            case let successNode as SuccessNode:
                AuthenticatedView(successNode: successNode, onSignOut: loginViewModel.reset)
            case let failureNode as FailureNode:
                ErrorView(message: failureNode.cause.localizedDescription, onRetry: retry)
            case let errorNode as ErrorNode:
                ErrorView(
                    message: errorNode.message.isEmpty ? "An error occurred." : errorNode.message,
                    onRetry: retry
                )
            case let continueNode as ContinueNode:
                LoginView(
                    continueNode: continueNode,
                    isLoading: loginViewModel.isLoading,
                    onNext: { Task { await loginViewModel.next(continueNode: continueNode) } }
                )
            default:
                LoginView(
                    continueNode: nil,
                    isLoading: loginViewModel.isLoading,
                    onNext: { Task { await loginViewModel.start() } }
                )
            }
        }
        .task {
            await loginViewModel.start()
        }
    }

    private func retry() {
        loginViewModel.reset()
        Task { await loginViewModel.start() }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.pingRed)

            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Try Again", action: onRetry)
                .buttonStyle(PingPrimaryButtonStyle())
                .padding(.horizontal, 40)
        }
        .padding(32)
    }
}
