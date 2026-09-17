//
//  SelectIdpCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingExternalIdP

/**
 * A SwiftUI view for selecting an external identity provider during authentication flows.
 *
 * This view presents a list of available external identity providers (e.g., Google, Facebook, Apple)
 * for the user to choose from. When a provider is selected, the callback records the choice and
 * immediately proceeds to the IdP authentication flow. This is commonly used when multiple social
 * login options are available.
 *
 * **User Action Required:** YES - User must select one identity provider from the available options.
 *
 * The UI displays a scrollable list of provider buttons, each styled prominently and labeled with
 * the provider name. The provider names are automatically capitalized for consistency.
 */
struct SelectIdpCallbackView: View {
    let callback: SelectIdpCallback
    let onNext: () -> Void
    
    var body: some View {
        ScrollView {

            LazyVStack(alignment: .center, spacing: PingTheme.Spacing.compact) {

                // Add a title for better context
                Text("Select a provider")
                    .pingSectionHeader()
                    .padding(.bottom, PingTheme.Spacing.small)

                ForEach(callback.providers) { provider in
                    Button(action: {
                        callback.value = provider.provider
                        self.onNext()
                    }) {
                        // Make the button label more descriptive and visually appealing
                        Text(provider.provider.capitalized)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.pingPrimary)
                }
            }
        }
        .padding(.vertical, PingTheme.Spacing.small)
    }
}
