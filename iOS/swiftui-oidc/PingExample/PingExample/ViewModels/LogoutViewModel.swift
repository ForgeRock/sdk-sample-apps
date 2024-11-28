// 
//  LogoutViewModel.swift
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

/*
    The LogoutViewModel class is used to manage the logout operation for the current user.
    The class provides the following functionality:
       - Logs out the current user.
 */
class LogoutViewModel: ObservableObject {
    
    @Published var message: String = ""
    
    func logout() async {
        await MainActor.run {
            if ConfigurationManager.shared.currentConfigurationViewModel?.environment == "AIC" {
                FRUser.currentUser?.logout()
            } else {
                FRUser.currentUser?.logout(presentingViewController: self.topViewController!)
            }
            message =  "Logout completed"
        }
    }
}
