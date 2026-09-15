//
//  SocialButtonView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOrchestrate
import PingDavinci
import PingBrowser
import PingExternalIdP

/// A view for social login buttons (Google, Facebook, Apple).
/// - Initiates the authentication flow when tapped and handles success/failure results.
public struct SocialButtonView: View {

    @StateObject public var socialButtonViewModel: SocialButtonViewModel

    public let onNext: (Bool) -> Void
    public let onStart: () -> Void

    @State private var isAuthenticating = false

    public var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.small) {
            Button {
                isAuthenticating = true
                Task {
                    let result = await socialButtonViewModel.startSocialAuthentication()
                    isAuthenticating = false
                    switch result {
                    case .success(_):
                        onNext(true)
                    case .failure(let error):
                        print(error)
                        onStart()
                    }
                }
            } label: {
                Text(socialButtonViewModel.idpCollector.label)
            }
            .buttonStyle(PingActionButtonStyle(role: .provider(
                background: socialButtonViewModel.providerBackground,
                foreground: .white
            )))
            .disabled(isAuthenticating)
        }
        .padding(.vertical, PingTheme.Spacing.small)
        .frame(maxWidth: .infinity)
    }
}

/// A view model class that manages social authentication button behavior and styling.
/// - Initiates the authentication process for the provider behind the button.
@MainActor
public class SocialButtonViewModel: ObservableObject {
    @Published public var isComplete: Bool = false
    public let idpCollector: IdpCollector

    public init(idpCollector: IdpCollector) {
        self.idpCollector = idpCollector
    }

    public func startSocialAuthentication() async -> Result<Bool, IdpExceptions> {
        return await idpCollector.authorize()
    }

    /// Provider-branded button surface: the DesignSystem's brand tokens
    /// (Ping red for Google, black for Apple, blue for Facebook), with
    /// `actionPrimary` as the fallback for unknown provider types.
    public var providerBackground: Color {
        switch idpCollector.idpType {
        case "APPLE":
            return PingTheme.Color.brandApple
        case "GOOGLE":
            return PingTheme.Color.brandGoogle
        case "FACEBOOK":
            return PingTheme.Color.brandFacebook
        default:
            return PingTheme.Color.actionPrimary
        }
    }
}
