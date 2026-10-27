/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci.mapper

import com.pingidentity.flutter.davinci.TokenMessage
import com.pingidentity.flutter.davinci.error.DaVinciErrorCodes
import com.pingidentity.flutter.davinci.error.classifyError
import com.pingidentity.oidc.Token
import com.pingidentity.oidc.exception.AuthorizeException
import com.pingidentity.orchestrate.Session
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class DaVinciSessionMapperTest {
    private fun sessionOf(code: () -> String) = object : Session {
        override val value: String
            get() = code()
    }

    @Test
    fun `session maps the authorization code`() {
        assertEquals("code-1", DaVinciSessionMapper.session(sessionOf { "code-1" }).authorizationCode)
    }

    @Test
    fun `an empty code is an auth error, as on iOS`() {
        val result = runCatching { DaVinciSessionMapper.session(sessionOf { "" }) }
            .classifyError(DaVinciErrorCodes.GET_SESSION)
        val error = assertFailsWith<com.pingidentity.flutter.davinci.FlutterError> { result.getOrThrow() }
        assertEquals(DaVinciErrorCodes.GET_SESSION, error.code)
        assertEquals("auth", error.details)
    }

    @Test
    fun `the SDK's AuthorizeException for a missing code is an auth error`() {
        val result = runCatching {
            DaVinciSessionMapper.session(sessionOf { throw AuthorizeException("Authorization code is missing.") })
        }.classifyError(DaVinciErrorCodes.GET_SESSION)
        val error = assertFailsWith<com.pingidentity.flutter.davinci.FlutterError> { result.getOrThrow() }
        assertEquals("auth", error.details)
        assertEquals("Authorization code is missing.", error.message)
    }

    @Test
    fun `token maps every field`() {
        val token = Token(
            accessToken = "access",
            tokenType = "Bearer",
            scope = "openid profile",
            expiresIn = 3599,
            refreshToken = "refresh",
            idToken = "id",
        )

        assertEquals(
            TokenMessage(
                accessToken = "access",
                tokenType = "Bearer",
                scope = "openid profile",
                expiresIn = 3599,
                refreshToken = "refresh",
                idToken = "id",
            ),
            DaVinciSessionMapper.token(token),
        )
    }

    @Test
    fun `token leaves absent optional fields null`() {
        val message = DaVinciSessionMapper.token(Token(accessToken = "access", expiresIn = 60))

        assertEquals(TokenMessage(accessToken = "access", expiresIn = 60), message)
    }
}
