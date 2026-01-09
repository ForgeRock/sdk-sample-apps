// 
//  LogOutViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//


import SwiftUI
import Combine
import PingOidc
import PingJourney
import KeylessSDK
/// A view model responsible for managing the logout functionality.
/// - Handles the logout process for the user and updates the state for UI display.
@MainActor
class LogOutViewModel: ObservableObject {
    /// A published property that holds the status of the logout process.
    @Published var logout: String = ""
    
    /// A published property that determines whether to de-enroll the keyless device during logout.
    @Published var shouldDeEnrollKeyless: Bool = false
    
    /// Performs the user logout process using the DaVinci SDK.
    /// - Executes the `logout()` method from the DaVinci or Journey user object asynchronously.
    /// - Updates the `logout` property with a completion message upon success.
    func logout() async {
        let journeyUser = await journey.journeyUser()
        await journeyUser?.logout()
        
        if shouldDeEnrollKeyless {
            Keyless.reset()
        }
        
        await MainActor.run {
            logout =  "Logout completed"
        }
    }
}
