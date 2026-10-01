//
//  ContinueNodeView.swift
//  Davinci
//
//  Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import SwiftUI
import PingOrchestrate
import PingDavinci
import PingExternalIdP
import PingProtect

/// A view for displaying and handling user interaction with a continue node in the authentication flow.
/// - This view renders different collectors based on their type and handles user input and validation.
struct ContinueNodeView: View {
    /// The continue node containing collectors and flow information.
    var continueNode: ContinueNode
    /// Callback for when a node is updated through user interaction.
    let onNodeUpdated: () -> Void
    /// Callback for when the flow should be started/restarted.
    let onStart: () -> Void
    /// Callback for when the user proceeds to the next step, with a flag indicating if this is a submission.
    let onNext: (Bool) -> Void

    /// The validation view model shared across collectors to manage form validation state.
    @EnvironmentObject var validationViewModel: ValidationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: PingTheme.Spacing.medium) {
            Text(continueNode.name)
                .pingScreenTitle()
                .frame(maxWidth: .infinity, alignment: .center)
            Text(continueNode.description)
                .pingBodySecondary()
                .frame(maxWidth: .infinity, alignment: .center)

            Divider()

            ForEach(continueNode.collectors, id: \.id) { collector in
                switch collector {
                case let flowCollector as FlowCollector:
                    FlowButtonView(field: flowCollector, onNext: onNext)
                case let passwordCollector as PasswordCollector:
                    PasswordView(field: passwordCollector, onNodeUpdated: onNodeUpdated)
                case let submitCollector as SubmitCollector:
                    SubmitButtonView(field: submitCollector, onNext: onNext)
                case let textCollector as TextCollector:
                    TextView(field: textCollector, onNodeUpdated: onNodeUpdated)
                case let labelCollector as LabelCollector:
                    LabelView(field: labelCollector)
                case let multiSelectCollector as MultiSelectCollector:
                    if multiSelectCollector.type == "COMBOBOX" {
                        ComboBoxView(field: multiSelectCollector, onNodeUpdated: onNodeUpdated)
                    } else {
                        CheckBoxView(field: multiSelectCollector, onNodeUpdated: onNodeUpdated)
                    }
                case let singleSelectCollector as SingleSelectCollector:
                    if singleSelectCollector.type == "DROPDOWN" {
                        DropdownView(field: singleSelectCollector, onNodeUpdated: onNodeUpdated)
                    } else {
                        RadioButtonView(field: singleSelectCollector, onNodeUpdated: onNodeUpdated)
                    }
                case let idpCollector as IdpCollector:
                    let viewModel = SocialButtonViewModel(idpCollector: idpCollector)
                    SocialButtonView(socialButtonViewModel: viewModel, onNext: onNext, onStart: onStart)
                case let deviceRegistrationCollector as DeviceRegistrationCollector:
                    DeviceRegistrationView(field: deviceRegistrationCollector, onNext: onNext)
                case let deviceAuthenticationCollector as DeviceAuthenticationCollector:
                    DeviceAuthenticationView(field: deviceAuthenticationCollector, onNext: onNext)
                case let phoneNumberCollector as PhoneNumberCollector:
                    PhoneNumberView(field: phoneNumberCollector, onNodeUpdated: onNodeUpdated)
                case let protectCollector as ProtectCollector:
                    PingProtectView(field: protectCollector, onNodeUpdated: onNodeUpdated).id(protectCollector.hash)
                default:
                    EmptyView()
                }
            }

            // Fallback Next Button
            if !continueNode.collectors.contains(where: { $0 is FlowCollector || $0 is SubmitCollector || $0 is DeviceRegistrationCollector || $0 is DeviceAuthenticationCollector }) {
                Button(action: { onNext(false) }) {
                    Text("Next")
                }
                .buttonStyle(.pingPrimary)
                .padding(.top, PingTheme.Spacing.medium)
            }
        }
        .padding(PingTheme.Spacing.screen)
    }
}
