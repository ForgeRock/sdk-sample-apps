//
//  SocialButtonView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import PingDavinci
import PingBrowser
import PingExternalIdP

/// A SwiftUI view that creates buttons for social identity provider authentication.
///
/// The SocialButtonView creates buttons for authenticating with social identity providers
/// like Apple, Google, or Facebook. It uses the SocialButtonViewModel to manage the
/// authentication process and styling.
///
/// Properties:
/// - socialButtonViewModel: ObservableObject that manages the authentication process and styling
/// - onNext: A callback function that navigates to the next step after successful authentication
/// - onStart: A callback function that returns to the start of the flow if authentication fails
///
/// The view initiates the authentication flow when the button is tapped and handles
/// success/failure results.
public struct SocialButtonView: View {
    
    @StateObject public var socialButtonViewModel: SocialButtonViewModel
    
    public let onNext: (Bool) -> Void
    public let onStart: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                Task {
                    let result = await socialButtonViewModel.startSocialAuthentication()
                    switch result {
                    case .success(_):
                        onNext(true)
                    case .failure(let error):
                        print(error)
                        onStart()
                    }
                }
            } label: {
                socialButtonViewModel.socialButtonText()
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

/// A view model class that manages social authentication button behavior and styling.
///
/// The SocialButtonViewModel handles the authentication process for social identity
/// providers and creates appropriate button styling based on the provider type.
///
/// Properties:
/// - isComplete: Published property that tracks authentication completion
/// - idpCollector: The IdpCollector that manages the authentication process with the provider
///
/// Methods:
/// - startSocialAuthentication(): Initiates the authentication process with the provider
/// - socialButtonText(): Creates a styled button view based on the provider type
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
    
    public func socialButtonText() -> some View {
        let bgColor: Color
        switch idpCollector.idpType {
        case "APPLE":
            bgColor = Color.appleButtonBackground
        case "GOOGLE":
            bgColor = Color.googleButtonBackground
        case "FACEBOOK":
            bgColor = Color.facebookButtonBackground
        default:
            bgColor = Color.themeButtonBackground
        }
        let text = Text(idpCollector.label)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 300, height: 50)
            .background(bgColor)
            .cornerRadius(15.0)
        
        return text
    }
}
