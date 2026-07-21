//
//  ContinueNodeView.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import PingJourneyPlugin
import PingOrchestrate
import PingFido

struct ContinueNodeView: View {
    let node: ContinueNode
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ForEach(node.callbacks, id: \.id) { callback in
                callbackView(for: callback)
            }

            if !hasSelfAdvancingCallback {
                Button("Next", action: onNext)
                    .buttonStyle(PingPrimaryButtonStyle())
            }
        }
    }

    // FIDO callbacks advance the node themselves after the OS prompt completes,
    // so we suppress the generic "Next" button when they are present.
    private var hasSelfAdvancingCallback: Bool {
        node.callbacks.contains { $0 is FidoRegistrationCallback || $0 is FidoAuthenticationCallback }
    }

    @ViewBuilder
    private func callbackView(for callback: any Callback) -> some View {
        switch callback {
        case let nameCallback as NameCallback:
            NameCallbackView(callback: nameCallback)
        case let passwordCallback as PasswordCallback:
            PasswordCallbackView(callback: passwordCallback)
        case let textOutputCallback as TextOutputCallback:
            Text(textOutputCallback.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 4)
        case let fidoRegistrationCallback as FidoRegistrationCallback:
            FidoRegistrationCallbackView(callback: fidoRegistrationCallback, onNext: onNext)
        case let fidoAuthenticationCallback as FidoAuthenticationCallback:
            FidoAuthenticationCallbackView(callback: fidoAuthenticationCallback, onNext: onNext)
        default:
            EmptyView()
        }
    }
}
