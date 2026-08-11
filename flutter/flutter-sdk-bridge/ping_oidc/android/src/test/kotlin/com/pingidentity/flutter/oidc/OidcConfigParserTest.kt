/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

/** Unit tests for [OidcConfigParser]'s validation and field-mapping logic. */
class OidcConfigParserTest {

    @Test
    fun `parse throws IllegalArgumentException when neither discoveryEndpoint nor openId is set`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                par = false,
            )

        assertFailsWith<IllegalArgumentException> { OidcConfigParser.parse(config) }
    }

    @Test
    fun `parse succeeds when only discoveryEndpoint is set`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                par = false,
            )

        val result = OidcConfigParser.parse(config)

        assertEquals("https://example.com/.well-known/openid-configuration", result.discoveryEndpoint)
    }

    @Test
    fun `parse succeeds when only openId is set, with no discoveryEndpoint`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                openId =
                    OidcOpenIdConfigMessage(
                        authorizationEndpoint = "https://example.com/authorize",
                        tokenEndpoint = "https://example.com/token",
                        userinfoEndpoint = "https://example.com/userinfo",
                    ),
                par = false,
            )

        val result = OidcConfigParser.parse(config)

        assertEquals("https://example.com/authorize", result.openId.authorizationEndpoint)
        assertEquals("https://example.com/token", result.openId.tokenEndpoint)
        assertEquals("https://example.com/userinfo", result.openId.userinfoEndpoint)
    }

    @Test
    fun `parse maps clientId and redirectUri`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                par = false,
            )

        val result = OidcConfigParser.parse(config)

        assertEquals("client-1", result.clientId)
        assertEquals("https://example.com/callback", result.redirectUri)
    }

    @Test
    fun `parse applies signOutRedirectUri on Android`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                signOutRedirectUri = "https://example.com/signout",
                par = false,
            )

        val result = OidcConfigParser.parse(config)

        assertEquals("https://example.com/signout", result.signOutRedirectUri)
    }

    @Test
    fun `parse leaves signOutRedirectUri null when unset`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                par = false,
            )

        val result = OidcConfigParser.parse(config)

        assertNull(result.signOutRedirectUri)
    }

    @Test
    fun `parse converts refreshThresholdSeconds to a Long`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                refreshThresholdSeconds = 120,
                par = false,
            )

        val result = OidcConfigParser.parse(config)

        assertEquals(120L, result.refreshThreshold)
    }

    @Test
    fun `parse maps par`() {
        val config =
            OidcConfigMessage(
                clientId = "client-1",
                redirectUri = "https://example.com/callback",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                par = true,
            )

        val result = OidcConfigParser.parse(config)

        assertEquals(true, result.par)
    }
}
