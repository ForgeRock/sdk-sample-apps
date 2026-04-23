//
//  OIDCViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth
import UIKit
import SwiftUI

/*
 The OIDCViewModel class is an ObservableObject that is used start the OIDC flow. The class has the following properties:
        status: The status of the user.
 
    The class has the following methods:
        startOIDC(): Starts the Centralized Login process.
        updateStatus(): Updates the status of the user.
    
 */
class OIDCViewModel: ObservableObject {
    
    @Published var status: String = ""
    
    /// Start the Centralized Login process. Returns an FRUser object.
    public func startOIDC() async throws -> FRUser {
        return try await withCheckedThrowingContinuation({
            (continuation: CheckedContinuation<FRUser, Error>) in
            Task { @MainActor in
                FRUser.browser()?
                    .set(presentingViewController: self.topViewController!)
                    .set(browserType: ConfigurationManager.shared.currentConfigurationViewModel?.getBrowserType() ?? .authSession)
                    .build().login { (user, error) in
                        if let frUser = user {
                            Task { @MainActor in
                                self.status = "User is authenticated"
                            }
                            continuation.resume(returning: frUser)
                        } else {
                            Task { @MainActor in
                                self.status = error?.localizedDescription ?? "Error was nil"
                            }
                            continuation.resume(throwing: error!)
                        }
                    }
            }
        })
    }
    
    /// Update the status of the user. Authenticated or logged out.
    public func updateStatus() {
        Task { @MainActor in
            if let _ = FRUser.currentUser {
                self.status = "User is authenticated"
            } else {
                self.status = "User is logged out"
            }
        }
    }
}
