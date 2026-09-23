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

/// A view model responsible for managing the logout functionality.
/// - Handles the logout process for the user and updates the state for UI display.
@MainActor
class LogOutViewModel: ObservableObject {
    /// Performs the user logout process using the DaVinci SDK.
    /// - Executes the `logout()` method from the DaVinci or Journey user object asynchronously.
    func logout() async {
        let journeyUser = await journey.journeyUser()
        await journeyUser?.logout()
    }
}
