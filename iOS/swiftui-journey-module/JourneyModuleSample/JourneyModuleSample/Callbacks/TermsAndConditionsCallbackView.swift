//
//  TermsAndConditionsCallbackView.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingJourney
import Combine

/**
 * A SwiftUI view for presenting and accepting terms and conditions during authentication flows.
 *
 * This view displays the terms and conditions text along with version and creation date information.
 * Users must review the terms and toggle their acceptance before proceeding. This is commonly used
 * during registration or when terms are updated and require re-acceptance. The toggle reflects
 * the current acceptance state.
 *
 * **User Action Required:** YES - User must toggle the switch to accept the terms and conditions.
 *
 * The UI displays the version, creation date, full terms text, and an acceptance toggle switch.
 * All information is presented in a clear hierarchy with appropriate styling.
 */
struct TermsAndConditionsCallbackView: View {
    let callback: TermsAndConditionsCallback
    let onNodeUpdated: () -> Void

    @State var accepted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Version
            if !callback.version.isEmpty {
                Text(callback.version)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Create Date
            if !callback.createDate.isEmpty {
                Text(callback.createDate)
                    .font(.headline)
                    .foregroundColor(.primary)
            }

            // Terms Text
            if !callback.terms.isEmpty {
                Text(callback.terms)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            // Acceptance Toggle
            Toggle("I accept the terms and conditions", isOn: $accepted)
                .toggleStyle(SwitchToggleStyle())
                .onChange(of: accepted) { newValue in
                    callback.accepted = newValue
                }
        }
        .padding()
        .onAppear {
            accepted = callback.accepted
        }
    }
}
