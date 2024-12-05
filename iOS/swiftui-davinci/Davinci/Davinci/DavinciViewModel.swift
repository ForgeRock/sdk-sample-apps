//
//  DavinciViewModel.swift
//  Davinci
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import Foundation
import PingDavinci
import PingOidc
import PingOrchestrate

/// Configures and initializes the DaVinci instance with the PingOne server and OAuth 2.0 client details.
/// - This configuration includes:
///   - Client ID
///   - Scopes
///   - Redirect URI
///   - Discovery Endpoint
///   - Other optional fields
    public let davinci = DaVinci.createDaVinci { config in
      //TODO: Provide here the Server configuration. Add the PingOne server Discovery Endpoint and the OAuth2.0 client details
      config.module(OidcModule.config) { oidcValue in
        oidcValue.clientId = "10a80cd7-a844-4cdf-b1c6-7dc2ccdb9769"
        oidcValue.scopes = ["openid", "email", "revoke"]
        oidcValue.redirectUri = "org.forgerock.demo://oauth2redirect"
        oidcValue.discoveryEndpoint = "https://auth.pingone.com/5e508bc0-91e7-409b-8514-783bad6d1811/as/.well-known/openid-configuration"
      }
    }

/// A view model that manages the flow and state of the DaVinci orchestration process.
/// - Responsible for:
///   - Starting the DaVinci flow
///   - Progressing to the next node in the flow
///   - Maintaining the current and previous flow state
///   - Handling loading states
class DavinciViewModel: ObservableObject {
  /// Published property that holds the current state node data.
  @Published public var data: StateNode = StateNode()
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
  private func startDavinci() async {
    await MainActor.run {
      isLoading = true
    }
    
    // Starts the DaVinci orchestration process and retrieves the first node.
    let node = await davinci.start()
    
    await MainActor.run {
      self.data = StateNode(currentNode: node, previousNode: node)
      isLoading = false
    }
  }
  
  /// Advances to the next node in the orchestration process.
  /// - Parameter node: The current node to progress from.
  public func next(node: Node) async {
    await MainActor.run {
      isLoading = true
    }
    if let nextNode = node as? ContinueNode {
      // Retrieves the next node in the flow.
      let next = await nextNode.next()
      await MainActor.run {
        self.data = StateNode(currentNode: next, previousNode: node)
        isLoading = false
      }
    }
  }
}

/// A model class that represents the state of the current and previous nodes in the DaVinci flow.
class StateNode {
  var currentNode: Node? = nil
  var previousNode: Node? = nil
  
  init(currentNode: Node?  = nil, previousNode: Node? = nil) {
    self.currentNode = currentNode
    self.previousNode = previousNode
  }
}
