//
//  OIDCViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth
import UIKit
import SwiftUI

class OIDCViewModel: ObservableObject {
    
    @Published var status: String = ""
    
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
