//
//  TokenViewModel.swift
//  PingExample
//
//  Copyright (c) 2024 Ping Identity. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import FRAuth

/*
 The TokenViewModel class is used to manage the access token for the current user.
 The class provides the following functionality:
 - Fetches the access token for the current user.
 - Revokes the OAuth2.0 tokens for the current user.
 - Refreshes the OAuth2.0 tokens for the current user.
 */
class AccessTokenViewModel: ObservableObject {
    
    @Published var accessToken: String = ""
    
    init() {
        Task {
            await accessToken()
        }
    }
    
    /// Fetches the access token for the current user.
    func accessToken() async {
        await withCheckedContinuation { continuation in
            if let user = FRUser.currentUser {
                user.getAccessToken(completion: { user, error in
                    Task { @MainActor in
                        if let token = user?.token {
                            self.accessToken = String(describing: token.value)
                        } else {
                            self.accessToken = error?.localizedDescription ?? "Error was nil"
                        }
                        continuation.resume()
                    }
                })
            } else {
                Task { @MainActor in
                    self.accessToken = "No user found, need to log in first."
                    continuation.resume()
                }
            }
        }
        
    }
    
    /// Revokes the OAuth2.0 tokens for the current user.
    public func revokeTokens() {
        if let user = FRUser.currentUser {
            user.revokeAccessToken { user, error in
                Task { @MainActor in
                    if let _ = user {
                        self.accessToken = "Token revoked"
                    } else {
                        self.accessToken = error?.localizedDescription ?? "Error was nil"
                    }
                }
            }
        }
    }
    
    /// Refreshes the OAuth2.0 tokens for the current user.
    public func refreshTokens() {
        if let user = FRUser.currentUser {
            user.refresh { user, error in
                Task { @MainActor in
                    if let token = user?.token {
                        self.accessToken = "Token refreshed: \(String(describing: token.value))"
                    } else {
                        self.accessToken = error?.localizedDescription ?? "Error was nil"
                    }
                }
            }
        }
        
    }
}
