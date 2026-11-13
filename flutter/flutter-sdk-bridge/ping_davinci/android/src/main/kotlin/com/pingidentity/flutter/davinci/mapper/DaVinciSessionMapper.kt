/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.flutter.davinci.SessionMessage
import com.pingidentity.flutter.davinci.TokenMessage
import com.pingidentity.oidc.Token
import com.pingidentity.oidc.exception.AuthorizeException
import com.pingidentity.orchestrate.Session

/** Maps the post-success native values onto their Pigeon messages. */
internal object DaVinciSessionMapper {
    /**
     * DaVinci's `SuccessNode.session.value` is the authorization code. The SDK throws
     * [AuthorizeException] when building a session without one (so such a node normally arrives
     * as a `FailureNode`); an empty code is treated the same way, which is what iOS returns.
     */
    fun session(session: Session): SessionMessage {
        val code = session.value
        if (code.isEmpty()) throw AuthorizeException("Authorization code is missing.")
        return SessionMessage(authorizationCode = code)
    }

    fun token(token: Token): TokenMessage =
        TokenMessage(
            accessToken = token.accessToken,
            tokenType = token.tokenType,
            scope = token.scope,
            expiresIn = token.expiresIn,
            refreshToken = token.refreshToken,
            idToken = token.idToken,
        )
}
