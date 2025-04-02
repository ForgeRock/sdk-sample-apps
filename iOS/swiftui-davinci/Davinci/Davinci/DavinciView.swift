//
//  DavinciView.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import SwiftUI
import PingOrchestrate
import PingDavinci

/// The main view for orchestrating the Davinci flow.
struct DavinciView: View {
    /// The view model that manages the Davinci flow logic.
    @StateObject private var davinciViewModel = DavinciViewModel()
    /// A binding to the navigation stack path.
    @Binding var path: [String]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack {
                    Spacer()
                    // Handle different types of nodes in the flow.
                    switch davinciViewModel.state.node {
                    case let continueNode as ContinueNode:
                        // Display the connector view for the next node.
                        ConnectorView(davinciViewModel: davinciViewModel, node: continueNode)
                    case is SuccessNode:
                        // Navigate to the token view on success.
                        VStack{}.onAppear {
                            path.removeLast()
                            path.append("Token")
                        }
                    case let failureNode as FailureNode:
                        let apiError = failureNode.cause as? ApiError
                        switch apiError {
                        case .error(_, _, let message):
                            // Show error message from the API.
                            ErrorView(message: message)
                        default:
                            // Show a default error message.
                            ErrorView(message: "unknown error")
                        }
                        // Handle failure node scenarios.
                        if let nextNode = davinciViewModel.state.previous as? ContinueNode {
                            ConnectorView(davinciViewModel: davinciViewModel, node: nextNode)
                        }
                    case let errorNode as ErrorNode:
                        /// Displays the error node view with detailed error information
                        ErrorNodeView(node: errorNode)
                        /// Provides a way to return to the previous valid node if available
                        if let nextNode = davinciViewModel.state.previous as? ContinueNode {
                            ConnectorView(davinciViewModel: davinciViewModel, node: nextNode)
                        }
                        
                        
                    default:
                        // Show an empty view for unhandled cases.
                        EmptyView()
                    }
                }
            }
            
            Spacer()
            
            // Show an activity indicator when loading.
            if davinciViewModel.isLoading {
                /// Semi-transparent overlay to indicate loading state
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                /// Circular progress indicator that provides visual feedback during loading operations
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(2)
                    .tint(.themeButtonBackground)
            }
        }
    }
}

/// A view for displaying the current step in the Davinci flow.
struct ConnectorView: View {
    /// View model for managing field validation across the form
    @StateObject var validationViewModel: ValidationViewModel  = ValidationViewModel()
    /// The Davinci view model managing the flow.
    @ObservedObject var davinciViewModel: DavinciViewModel
    /// The next node to process in the flow.
    public var node: ContinueNode
    
    var body: some View {
        VStack {
            /// App logo displayed at the top of the view
            Image("Logo").resizable().scaledToFill().frame(width: 100, height: 100)
            
            /// The main node view that handles user interactions with the current flow step
            ContinueNodeView(continueNode: node,
                             onNodeUpdated:  { davinciViewModel.refresh() },
                             onStart: { Task { await davinciViewModel.startDavinci() }},
                             onNext: { isSubmit in Task {
                /// Determines if validation should occur based on the submission state and node configuration
                validationViewModel.shouldValidate = isSubmit && davinciViewModel.shouldValidate(node: node)
                if !validationViewModel.shouldValidate {
                    await davinciViewModel.next(node: node)
                }
            }})
            .environmentObject(validationViewModel)
        }
    }
}
