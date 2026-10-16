//
//  LoginViewModel.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import Observation
import PingJourney
import PingOrchestrate

@Observable
@MainActor
final class LoginViewModel {
    var node: Node?
    var isLoading = false

    func start() async {
        let journeyName = UserDefaults.standard.bool(forKey: UserDefaultsKey.biometricsEnabled)
            ? JourneyName.fidoAuthentication
            : JourneyName.login
        await startJourney(name: journeyName)
    }

    func startJourney(name: String) async {
        isLoading = true
        defer { isLoading = false }
        node = await AppJourney.shared.journey.start(name)
    }

    func next(continueNode: ContinueNode) async {
        isLoading = true
        defer { isLoading = false }
        node = await continueNode.next()
    }

    func reset() {
        node = nil
    }
}
