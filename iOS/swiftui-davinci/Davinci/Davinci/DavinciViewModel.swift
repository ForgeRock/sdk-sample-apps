//
//  DavinciViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingDavinci
import PingOidc
import PingOrchestrate
import PingExternalIdP
import PingProtect

/// Configures and initializes the DaVinci instance with the PingOne server and OAuth 2.0 client details.
/// - This configuration includes:
///   - Client ID
///   - Scopes
///   - Redirect URI
///   - Discovery Endpoint
///   - Other optional fields
public let davinci = DaVinci.createDaVinci { config in
    //TODO: Provide here the Server configuration. Add the PingOne server Discovery Endpoint and the OAuth2.0 client details
    config.module(PingDavinci.OidcModule.config) { oidcValue in
        oidcValue.clientId = <#"Client ID"#>
        oidcValue.scopes = [<#"scope1"#>, <#"scope2"#>, <#"scope3"#>]
        oidcValue.redirectUri = <#"Redirect URI"#>
        oidcValue.discoveryEndpoint = <#"Discovery Endpoint"#>
        oidcValue.acrValues = <#"acrValue1"#>
    }
    
    // Configure PingProtect module for fraud detection and risk assessment
    /*
     The DaVinci Client for Android and iOS provide the ProtectLifecycle module for simplifying the management of data collection.

     As a DaVinci Client module, it is aware of the current state of authentication, and can automatically pause and resume behavioral data collection when required.

     Configure the ProtectLifecycle module in your DaVinci Client configuration, as with other modules (Optional).
     
     config.module(ProtectLifecycleModule.config) { protectValue in
             protectValue.isBehavioralDataCollection = true
             protectValue.isLazyMetadata = true
             protectValue.envId = "[END_ID]"
             protectValue.deviceAttributesToIgnore = ["deviceId"]
             protectValue.isConsoleLogEnabled = true

             protectValue.pauseBehavioralDataOnSuccess = true
             protectValue.resumeBehavioralDataOnStart = true
         }
     
     You can choose not to initialize data collection on app startup and instead initialize it on-demand, when your DaVinci flow reaches the relevant node.
     
     The DaVinci for Android and iOS will automatically initialize data collection when calling the collect() method in response to receiving a ProtectCollector from PingOne. Learn more in Return captured data to a DaVinci flow.
     */
    
}

/// A view model that manages the flow and state of the DaVinci orchestration process.
/// - Responsible for:
///   - Starting the DaVinci flow
///   - Progressing to the next node in the flow
///   - Maintaining the current and previous flow state
///   - Handling loading states
@MainActor
class DavinciViewModel: ObservableObject {
    /// Published property that holds the current state node data.
    @Published public var state: DavinciState = DavinciState()
    /// Published property to track whether the view is currently loading.
    @Published public var isLoading: Bool = false
    
    /// Initializes the view model and starts the DaVinci orchestration process.
    init() {
        Task {
            await startDavinci()
        }
    }
    
    /// Starts the DaVinci orchestration process.
    /// - Sets the initial node and updates the `data` property with the starting node.
    public func startDavinci() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Starts the DaVinci orchestration process and retrieves the first node.
        let next = await davinci.start()
        
        await MainActor.run {
            self.state = DavinciState(previous: next , node: next)
            isLoading = false
        }
        
        // Direct initialization using the Protect interface (Optional)
        /*
         await Protect.config { protectConfig in
             protectConfig.isBehavioralDataCollection = true
             protectConfig.isLazyMetadata = true
             protectConfig.envId = "3072206d-c6ce-ch15-m0nd-f87e972c7cc3"
             protectConfig.deviceAttributesToIgnore = ["deviceId", "serialNumber"]
             protectConfig.isConsoleLogEnabled = true
         }
         
         // Initialize the Collection.
         
         try await Protect.initialize()

         print("Protect data collection initialized.")
         */
    }
    
    /// Advances to the next node in the orchestration process.
    /// - Parameter node: The current node to progress from.
    public func next(node: Node) async {
        await MainActor.run {
            isLoading = true
        }
        if let current = node as? ContinueNode {
            // Retrieves the next node in the flow.
            let next = await current.next()
            await MainActor.run {
                self.state = DavinciState(previous: current, node: next)
                isLoading = false
            }
        }
    }
    
    /// Determines if field validation should be performed before advancing to the next node.
    /// - Parameter node: The current node being processed.
    /// - Returns: A boolean indicating whether validation should be performed.
    public func shouldValidate(node: ContinueNode) -> Bool {
        var shouldValidate = false
        for collector in node.collectors {
            // Check if the collector is a social collector and if it has a resume request.
            // In that case, we should not validate the collectors and continue with the submission of the flow.
            if let socialCollector = collector as? IdpCollector {
                if socialCollector.resumeRequest != nil {
                    shouldValidate = false
                    return shouldValidate
                }
            }
            if let collector = collector as? ValidatedCollector {
                if collector.validate().count > 0 {
                    shouldValidate = true
                }
            }
        }
        return shouldValidate
    }
    
    /// Refreshes the current state to trigger UI updates.
    /// - This function maintains the same nodes but updates the state object to force view refreshes.
    public func refresh() {
        state = DavinciState(previous: state.previous, node: state.node)
    }
}

/// A model class that represents the state of the current and previous nodes in the DaVinci flow.
class DavinciState {
    /// The previous node in the flow, which may be used for navigation or recovery from errors.
    var previous: Node? = nil
    /// The current active node in the flow.
    var node: Node? = nil
    
    /// Initializes a new DavinciState with optional previous and current nodes.
    /// - Parameters:
    ///   - previous: The previous node in the flow, if any.
    ///   - node: The current node in the flow, if any.
    init(previous: Node?  = nil, node: Node? = nil) {
        self.previous = previous
        self.node = node
    }
}


/// A view model for managing validation state across form fields.
@MainActor
public class ValidationViewModel: ObservableObject {
    /// Indicates whether validation should be performed on the current form fields.
    @Published var shouldValidate = false
}
