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

class TokenViewModel: ObservableObject {
    
    @Published var accessToken: String = ""
    
    init() {
        Task {
            await accessToken()
        }
    }
    
    func accessToken() async {
        Task { @MainActor in
            FRUser.currentUser?.getAccessToken(completion: { user, error in
                if let token = user?.token {
                    self.accessToken = String(describing: token.value)
                } else {
                    self.accessToken = error?.localizedDescription ?? "Error was nil"
                }
            })
        }
    }
}
