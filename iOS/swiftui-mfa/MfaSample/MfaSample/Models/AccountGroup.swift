//
//  AccountGroup.swift
//  MfaSample
//
//  Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
//
//  This software may be modified and distributed under the terms
//  of the MIT license. See the LICENSE file for details.
//

import Foundation
import PingOath
import PingPush

/// Data structure to represent a group of credentials (OATH or Push) with the same issuer/account.
/// This is used to display a unified account view regardless of authentication method.
struct AccountGroup: Identifiable {
    let id = UUID()
    let issuer: String
    let accountName: String
    let displayIssuer: String
    let displayAccountName: String
    let oathCredentials: [OathCredential]
    let pushCredentials: [PushCredential]

    init(
        issuer: String,
        accountName: String,
        displayIssuer: String,
        displayAccountName: String,
        oathCredentials: [OathCredential] = [],
        pushCredentials: [PushCredential] = []
    ) {
        self.issuer = issuer
        self.accountName = accountName
        self.displayIssuer = displayIssuer
        self.displayAccountName = displayAccountName
        self.oathCredentials = oathCredentials
        self.pushCredentials = pushCredentials
    }

    /// Check if this account group has any locked credentials.
    var isLocked: Bool {
        oathCredentials.contains { $0.isLocked } || pushCredentials.contains { $0.isLocked }
    }

    /// Get the locking policy name from the first locked credential.
    var lockingPolicy: String? {
        oathCredentials.first { $0.isLocked }?.lockingPolicy
            ?? pushCredentials.first { $0.isLocked }?.lockingPolicy
    }

    /// Returns the image URL for the account, preferring OATH over Push credentials.
    var imageURL: String? {
        oathCredentials.first?.imageURL ?? pushCredentials.first?.imageURL
    }
}
