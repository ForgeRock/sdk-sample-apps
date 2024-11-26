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

public let davinci = DaVinci.createDaVinci { config in
  config.module(OidcModule.config) { oidcValue in
    oidcValue.clientId = <#"Client ID"#>
    oidcValue.scopes = [<#"scope1"#>, <#"scope2"#>, <#"scope3"#>]
    oidcValue.redirectUri = <#"Redirect URI"#>
    oidcValue.discoveryEndpoint = <#"Discovery Endpoint"#>
  }
}

class DavinciViewModel: ObservableObject {
  @Published public var data: StateNode = StateNode()
  @Published public var isLoading: Bool = false
  
  init() {
    Task {
      await startDavinci()
    }
  }
  
  private func startDavinci() async {
    await MainActor.run {
      isLoading = true
    }
    
    let node = await davinci.start()
    
    await MainActor.run {
      self.data = StateNode(currentNode: node, previousNode: node)
      isLoading = false
    }
  }
  
  public func next(node: Node) async {
    await MainActor.run {
      isLoading = true
    }
    if let nextNode = node as? ContinueNode {
      let next = await nextNode.next()
      await MainActor.run {
        self.data = StateNode(currentNode: next, previousNode: node)
        isLoading = false
      }
    }
  }
}

class StateNode {
  var currentNode: Node? = nil
  var previousNode: Node? = nil
  
  init(currentNode: Node?  = nil, previousNode: Node? = nil) {
    self.currentNode = currentNode
    self.previousNode = previousNode
  }
}
