//
//  KeylessViewModel.swift
//  JourneyModuleSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import PingJourney

struct KeylessPayload: Codable {
    let keylessAPIKey: String
    let keylessHost: String
    let op_id: String
}

struct KeylessResponse: Codable {
    let jwt: String
    let clientState: String
}


class KeylessViewModel {
    let callback: HiddenValueCallback? = nil
}
