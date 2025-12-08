//
//  ContinueNodeView.swift
//  Davinci
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
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
        VStack(alignment: .leading, spacing: 16) {
            /// Title display showing the node name
            Text(continueNode.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(Color.gray)
            /// Description text providing context about the current step
            Text(continueNode.description)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(Color.gray)
            
            Divider()
            
            /// Renders the appropriate view for each collector in the node
            ForEach(continueNode.collectors , id: \.id) { collector in
                switch collector {
                case is FlowCollector:
                    if let flowCollector = collector as? FlowCollector {
                        /// View for flow-related buttons that can navigate between flow branches
                        FlowButtonView(field: flowCollector, onNext: onNext)
                    }
                case is PasswordCollector:
                    if let passwordCollector = collector as? PasswordCollector {
                        /// View for password input fields with secure entry
                        PasswordView(field: passwordCollector, onNodeUpdated: onNodeUpdated)
                    }
                case is SubmitCollector:
                    if let submitCollector = collector as? SubmitCollector {
                        /// View for form submission buttons
                        SubmitButtonView(field: submitCollector, onNext: onNext)
                    }
                case is TextCollector:
                    if let textCollector = collector as? TextCollector {
                        /// View for text input fields
                        TextView(field: textCollector, onNodeUpdated: onNodeUpdated)
                    }
                case is LabelCollector:
                    if let labelCollector = collector as? LabelCollector {
                        /// View for displaying static text labels
                        LabelView(field: labelCollector)
                    }
                case is MultiSelectCollector:
                    if let multiSelectCollector = collector as? MultiSelectCollector {
                        if multiSelectCollector.type == "COMBOBOX" {
                            /// View for combo box selection with multiple choices
                            ComboBoxView(field: multiSelectCollector, onNodeUpdated: onNodeUpdated)
                        } else {
                            /// View for checkbox selection with multiple choices
                            CheckBoxView(field: multiSelectCollector, onNodeUpdated: onNodeUpdated)
                        }
                    }
                case is SingleSelectCollector:
                    if let singleSelectCollector = collector as? SingleSelectCollector {
                        if singleSelectCollector.type == "DROPDOWN" {
                            /// View for dropdown selection with single choice
                            DropdownView(field: singleSelectCollector, onNodeUpdated: onNodeUpdated)
                        } else {
                            /// View for radio button selection with single choice
                            RadioButtonView(field: singleSelectCollector, onNodeUpdated: onNodeUpdated)
                        }
                    }
                case let deviceRegistrationCollector as DeviceRegistrationCollector:
                    DeviceRegistrationView(field: deviceRegistrationCollector, onNext: onNext)
                case let deviceAuthenticationCollector as DeviceAuthenticationCollector:
                    DeviceAuthenticationView(field: deviceAuthenticationCollector, onNext: onNext)
                case let phoneNumberCollector as PhoneNumberCollector:
                    PhoneNumberView(field: phoneNumberCollector, onNodeUpdated: onNodeUpdated)
                case is IdpCollector:
                    if let idpCollector = collector as? IdpCollector {
                        /// View model to handle identity provider interactions
                        let viewModel = SocialButtonViewModel(idpCollector: idpCollector)
                        /// View for social login buttons (Google, Facebook, etc.)
                        SocialButtonView(socialButtonViewModel: viewModel, onNext: onNext, onStart: onStart)
                    }
                case is ProtectCollector:
                    if let protectCollector = collector as? ProtectCollector {
                        /// View for PingProtect fraud detection and risk assessment
                        PingProtectView(field: protectCollector, onNodeUpdated: onNodeUpdated)
                    }
                default:
                    EmptyView()
                }
            }
            
            // Fallback Next Button
            if !continueNode.collectors.contains(where: { $0 is FlowCollector || $0 is SubmitCollector || $0 is DeviceRegistrationCollector || $0 is DeviceAuthenticationCollector }) {
                Button(action: { onNext(false) }) {
                    Text("Next")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeButtonBackground)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
            }
        }
        .padding()
    }
}
