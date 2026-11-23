//
//  RegistrationViewModel.swift
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
final class RegistrationViewModel {
    var node: Node?
    var isLoading = false
    var isRegistered = false
    var isFailure = false

    func startRegistration() async {
        isLoading = true
        isRegistered = false
        isFailure = false
        defer { isLoading = false }
        node = await AppJourney.shared.journey.start(JourneyName.fidoRegistration) { options in
            options.forceAuth = true
        }
    }

    func next(continueNode: ContinueNode) async {
        isLoading = true
        defer { isLoading = false }
        let nextNode = await continueNode.next()
        node = nextNode
        if nextNode is SuccessNode {
            UserDefaults.standard.set(true, forKey: UserDefaultsKey.biometricsEnabled)
            isRegistered = true
        } else if nextNode is FailureNode || nextNode is ErrorNode {
            isFailure = true
        }
    }
}
