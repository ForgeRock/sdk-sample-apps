//
//  AuthenticatedViewModel.swift
//  PasskeysSwiftUI
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Observation
import PingJourney
import PingOidc

@Observable
@MainActor
final class AuthenticatedViewModel {
    var userInfo: [String: Any] = [:]
    var isLoadingUserInfo = false
    var userInfoError: String?
    var isSignedOut = false

    func loadUserInfo() async {
        isLoadingUserInfo = true
        userInfoError = nil
        defer { isLoadingUserInfo = false }

        guard let user = await AppJourney.shared.journey.journeyUser() else {
            userInfoError = "No authenticated user found."
            return
        }

        switch await user.userinfo(cache: false) {
        case .success(let info):
            userInfo = info
        case .failure(let error):
            userInfoError = error.localizedDescription
        }
    }

    func signOut() async {
        _ = await AppJourney.shared.journey.signOff()
        isSignedOut = true
    }
}
