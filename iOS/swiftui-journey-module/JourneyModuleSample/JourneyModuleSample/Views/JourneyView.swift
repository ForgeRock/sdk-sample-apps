//
//  JourneyView.swift
//  PingExample
//
//  Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import SwiftUI
import PingOrchestrate
import PingJourney
import PingProtect
import PingExternalIdP
import PingDeviceProfile
import PingFido
import PingReCaptchaEnterprise
import PingBinding
import PingCommons
internal import PingJourneyPlugin

struct JourneyView: View {
    /// The view model that manages the Journey flow logic.
    @StateObject private var journeyViewModel = JourneyViewModel()
    /// A binding to the navigation stack path.
    @Binding var path: [MenuItem]
    
    var body: some View {
        ZStack {
            if journeyViewModel.showJourneyNameInput {
                // Show journey name input screen
                JourneyNameInputView(journeyViewModel: journeyViewModel)
            } else {
                // Show the normal journey flow
                ScrollView {
                    VStack {
                        Spacer()
                        // Handle different types of nodes in the Journey.
                        switch journeyViewModel.state.node {
                        case let continueNode as ContinueNode:
                            // Display the callback view for the next node.
                            CallbackView(journeyViewModel: journeyViewModel, node: continueNode)
                        case let errorNode as ErrorNode:
                            // Handle server-side errors (e.g., invalid credentials)
                            // Display error to the user
                            ErrorNodeView(node: errorNode)
                        case let failureNode as FailureNode:
                            ErrorView(message: failureNode.cause.localizedDescription)
                        case is SuccessNode:
                            // Authentication successful, retrieve the session
                            VStack{}.onAppear {
                                path.removeLast()
                                path.append(.token)
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
    }
}

/// A view for collecting the journey name before starting the flow
struct JourneyNameInputView: View {
    @ObservedObject var journeyViewModel: JourneyViewModel
    @State private var journeyName: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image("Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
            
            VStack(spacing: 16) {
                Text("Enter Journey Name")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Journey Name", text: $journeyName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .onAppear() { journeyName = journeyViewModel.getSavedJourneyName() }
                
                Spacer()
                
                NextButton(title: "Start Journey") {
                    Task {
                        journeyViewModel.saveJourneyName(journeyName)
                        await journeyViewModel.startJourney(with: journeyName)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

/// A view for displaying the current step in the Journey flow.
struct CallbackView: View {
    /// The Journey view model managing the flow.
    @ObservedObject var journeyViewModel: JourneyViewModel
    /// The next node to process in the flow.
    public var node: ContinueNode
    
    var body: some View {
        VStack {
            Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
            
            JourneyNodeView(continueNode: node,
                            onNodeUpdated:  { journeyViewModel.refresh() },
                            onStart: { Task { await journeyViewModel.startJourney(with: journeyViewModel.getSavedJourneyName()) }},
                            onNext: { Task {
                print("Next button tapped")
                await journeyViewModel.next(node: node)
            }})
        }
        
    }
}

struct JourneyNodeView: View {
    var continueNode: ContinueNode
    let onNodeUpdated: () -> Void
    let onStart: () -> Void
    let onNext: () -> Void
    
    private var showNext: Bool {
        !continueNode.callbacks.contains { callback in
            callback is ConfirmationCallback ||
            callback is SuspendedTextOutputCallback ||
            // TODO: Uncomment for 2.0.0 release
//            callback is PingOneProtectInitializeCallback ||
//            callback is PingOneProtectEvaluationCallback ||
//            callback is IdpCallback ||
            callback is FidoRegistrationCallback ||
            callback is FidoAuthenticationCallback ||
            callback is DeviceBindingCallback ||
            callback is DeviceSigningVerifierCallback
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            ForEach(Array(continueNode.callbacks.enumerated()), id: \.offset) { index, callback in
                switch callback {
                case let booleanCallback as BooleanAttributeInputCallback:
                    BooleanAttributeInputCallbackView(callback: booleanCallback, onNodeUpdated: onNodeUpdated)
                    
                case let choiceCallback as ChoiceCallback:
                    ChoiceCallbackView(callback: choiceCallback, onNodeUpdated: onNodeUpdated)
                    
                case let confirmationCallback as ConfirmationCallback:
                    ConfirmationCallbackView(callback: confirmationCallback, onSelected: onNext)
                    
                case let consentCallback as ConsentMappingCallback:
                    ConsentMappingCallbackView(callback: consentCallback, onNodeUpdated: onNodeUpdated)
                    
                case let kbaCallback as KbaCreateCallback:
                    KbaCreateCallbackView(callback: kbaCallback, onNodeUpdated: onNodeUpdated)
                    
                case let numberCallback as NumberAttributeInputCallback:
                    NumberAttributeInputCallbackView(callback: numberCallback, onNodeUpdated: onNodeUpdated)
                    
                case let passwordCallback as PasswordCallback:
                    PasswordCallbackView(callback: passwordCallback, onNodeUpdated: onNodeUpdated)
                    
                case let pollingCallback as PollingWaitCallback:
                    PollingWaitCallbackView(callback: pollingCallback, onTimeout: onNext)
                    
                case let stringCallback as StringAttributeInputCallback:
                    StringAttributeInputCallbackView(callback: stringCallback, onNodeUpdated: onNodeUpdated)
                    
                case let termsCallback as TermsAndConditionsCallback:
                    TermsAndConditionsCallbackView(callback: termsCallback, onNodeUpdated: onNodeUpdated)
                    
                case let textInputCallback as TextInputCallback:
                    TextInputCallbackView(callback: textInputCallback, onNodeUpdated: onNodeUpdated)
                    
                case let textOutputCallback as TextOutputCallback:
                    TextOutputCallbackView(callback: textOutputCallback)
                    
                case let suspendedTextCallback as SuspendedTextOutputCallback:
                    TextOutputCallbackView(callback: suspendedTextCallback)
                    
                case let nameCallback as NameCallback:
                    NameCallbackView(callback: nameCallback, onNodeUpdated: onNodeUpdated)
                    
                case let validatedUsernameCallback as ValidatedUsernameCallback:
                    ValidatedUsernameCallbackView(callback: validatedUsernameCallback, onNodeUpdated: onNodeUpdated)
                    
                case let validatedPasswordCallback as ValidatedPasswordCallback:
                    ValidatedPasswordCallbackView(callback: validatedPasswordCallback, onNodeUpdated: onNodeUpdated)
                    
                    // TODO: Uncomment for 2.0.0 release. 
//                case let protectInitCallback as PingOneProtectInitializeCallback:
//                    PingOneProtectInitializeCallbackView(callback: protectInitCallback, onNext: onNext)
//                    
//                case let protectEvalCallback as PingOneProtectEvaluationCallback:
//                    PingOneProtectEvaluationCallbackView(callback: protectEvalCallback, onNext: onNext)
//                    
//                case let selectIdpCallback as SelectIdpCallback:
//                    SelectIdpCallbackView(callback: selectIdpCallback, onNext: onNext)
//                    
//                case let idpCallback as IdpCallback:
//                    let idpCallbackViewModel = IdpCallbackViewModel(callback: idpCallback)
//                    IdpCallbackView(viewModel: idpCallbackViewModel, onNext: onNext)

                case let deviceProfileCallback as DeviceProfileCallback:
                    DeviceProfileCallbackView(callback: deviceProfileCallback, onNext: onNext)

                case let fidoRegistrationCallback as FidoRegistrationCallback:
                    FidoRegistrationCallbackView(callback: fidoRegistrationCallback, onNext: onNext)
                    
                case let fidoAuthenticationCallback as FidoAuthenticationCallback:
                    FidoAuthenticationCallbackView(callback: fidoAuthenticationCallback, onNext: onNext)
                    
                case let reCaptchaEnterpriseCallback as ReCaptchaEnterpriseCallback:
                    ReCaptchaEnterpriseCallbackView(callback: reCaptchaEnterpriseCallback, onNext: onNext).id(reCaptchaEnterpriseCallback.id)
                    
                case let deviceBindingCallback as DeviceBindingCallback:
                    DeviceBindingCallbackView(callback: deviceBindingCallback, onNext: onNext)

                case let deviceSigningVerifierCallback as DeviceSigningVerifierCallback:
                    DeviceSigningVerifierCallbackView(callback: deviceSigningVerifierCallback, onNext: onNext)
                    
                case _ as HiddenValueCallback:
                    EmptyView()
                    
                default:
                    Text("Unsupported callback type")
                }
            }
            
            if showNext {
                Button(action: {
                    // TODO: Uncomment for 2.0.0 release
//                    if let selectIDPCallback = continueNode.callbacks.first(where: {
//                        $0 is SelectIdpCallback
//                    }) as? SelectIdpCallback {
//                        selectIDPCallback.value = "localAuthentication"
//                    }
                    onNext()
                }) {
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
