/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import Foundation
import PingOidc
import PingOrchestrate

/// Maps the post-success native values onto their Pigeon messages.
enum DaVinciSessionMapper {
    /// DaVinci's `SuccessNode.session.value` is the authorization code. iOS's `SessionResponse`
    /// returns `""` when it is missing, where Android throws `AuthorizeException`; both become an
    /// `auth` error.
    static func session(_ session: Session) throws -> SessionMessage {
        let code = session.value
        guard !code.isEmpty else {
            throw OidcError.authorizeError(message: "Authorization code is missing.")
        }
        return SessionMessage(authorizationCode: code)
    }

    static func token(_ token: Token) -> TokenMessage {
        TokenMessage(
            accessToken: token.accessToken,
            tokenType: token.tokenType,
            scope: token.scope,
            expiresIn: token.expiresIn,
            refreshToken: token.refreshToken,
            idToken: token.idToken
        )
    }

    /// `UserInfo` is `[String: Sendable]` decoded by `JSONSerialization`, so every value is
    /// already codec-safe (`NSNull` included); only the key type needs widening for Pigeon.
    static func userInfo(_ userInfo: UserInfo) -> [String?: Any?] {
        Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key as String?, $0.value as Any?) })
    }
}
