/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.journey

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.oidc.OidcConfigHandle
import com.pingidentity.flutter.core.oidc.OidcOpenIdConfig
import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.oidc.OidcClientConfig
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Test-local [OidcConfigHandle] implementation, registered directly into
 * [CoreRuntime.oidcClientRegistry] so these tests can exercise [JourneyConfigParser]'s
 * handle-resolution path with no `ping_oidc` test dependency.
 */
private class FakeOidcConfigHandle(
    override val clientId: String = "client-1",
    override val discoveryEndpoint: String? = "https://example.com/.well-known/openid-configuration",
    override val openId: OidcOpenIdConfig? = null,
    override val redirectUri: String? = "https://example.com/callback",
    override val scopes: List<String> = listOf("openid", "profile"),
    override val acrValues: String? = null,
    override val signOutRedirectUri: String? = null,
    override val state: String? = null,
    override val nonce: String? = null,
    override val uiLocales: String? = null,
    override val refreshThreshold: Long? = null,
    override val loginHint: String? = null,
    override val display: String? = null,
    override val prompt: String? = null,
    override val additionalParameters: Map<String, String> = emptyMap(),
    override val par: Boolean = false,
) : NativeHandle, OidcConfigHandle

/**
 * Unit tests for [JourneyConfigParser]'s handle-resolution logic.
 *
 * These call [resolveOidcHandle]/[applyHandle] directly rather than through
 * [JourneyConfigParser.parse] — `parse` always constructs a full native
 * `Journey`, and `Journey.kt`'s own builder unconditionally reads
 * `android.os.LocaleList.getDefault()` (unrelated to this phase, and not this repo's own code),
 * which the stub `android.jar` used by plain JVM unit tests can't satisfy. `hasOidcConfig` is a
 * pure field check and is unaffected, so it's tested directly too.
 */
class JourneyConfigParserTest {
    private val registeredIds = mutableListOf<String>()

    private fun register(handle: FakeOidcConfigHandle): String {
        val id = CoreRuntime.oidcClientRegistry.register(handle)
        registeredIds.add(id)
        return id
    }

    @AfterTest
    fun cleanUp() {
        registeredIds.forEach { CoreRuntime.oidcClientRegistry.remove(it) }
        registeredIds.clear()
    }

    @Test
    fun `resolveOidcHandle returns the registered handle`() {
        val id = register(FakeOidcConfigHandle(clientId = "client-42"))

        val handle = resolveOidcHandle(id)

        assertEquals("client-42", handle.clientId)
    }

    @Test
    fun `resolveOidcHandle throws IllegalArgumentException for an unregistered id`() {
        val error =
            assertFailsWith<IllegalArgumentException> {
                resolveOidcHandle("not-registered")
            }
        assertTrue(error.message!!.contains("OIDC client instance not found for id=not-registered"))
    }

    @Test
    fun `resolveOidcHandle throws when the handle has neither discoveryEndpoint nor openId`() {
        val id = register(FakeOidcConfigHandle(discoveryEndpoint = null, openId = null))

        val error =
            assertFailsWith<IllegalArgumentException> { resolveOidcHandle(id) }
        assertTrue(error.message!!.contains("does not expose discoveryEndpoint or openId"))
    }

    @Test
    fun `resolveOidcHandle succeeds when the handle exposes only openId, no discoveryEndpoint`() {
        val id =
            register(
                FakeOidcConfigHandle(
                    discoveryEndpoint = null,
                    openId =
                        OidcOpenIdConfig(
                            authorizationEndpoint = "https://example.com/authorize",
                            tokenEndpoint = "https://example.com/token",
                            userinfoEndpoint = "https://example.com/userinfo",
                        ),
                )
            )

        val handle = resolveOidcHandle(id)

        assertNull(handle.discoveryEndpoint)
        assertEquals("https://example.com/authorize", handle.openId?.authorizationEndpoint)
    }

    @Test
    fun `applyHandle maps clientId, discoveryEndpoint, redirectUri and scopes`() {
        val handle =
            FakeOidcConfigHandle(
                clientId = "client-42",
                discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
                redirectUri = "https://example.com/callback",
                scopes = listOf("openid", "email"),
            )

        val config = OidcClientConfig().apply { applyHandle(handle) }

        assertEquals("client-42", config.clientId)
        assertEquals("https://example.com/.well-known/openid-configuration", config.discoveryEndpoint)
        assertEquals("https://example.com/callback", config.redirectUri)
        assertEquals(setOf("openid", "email"), config.scopes)
    }

    @Test
    fun `applyHandle maps openId, coercing null endpoints to empty strings`() {
        val handle =
            FakeOidcConfigHandle(
                openId =
                    OidcOpenIdConfig(
                        authorizationEndpoint = "https://example.com/authorize",
                        tokenEndpoint = "https://example.com/token",
                        userinfoEndpoint = "https://example.com/userinfo",
                    ),
            )

        val config = OidcClientConfig().apply { applyHandle(handle) }

        assertEquals("https://example.com/authorize", config.openId.authorizationEndpoint)
        assertEquals("", config.openId.endSessionEndpoint)
        assertEquals("", config.openId.pingEndIdpSessionEndpoint)
        assertEquals("", config.openId.revocationEndpoint)
    }

    @Test
    fun `applyHandle maps par`() {
        val handle = FakeOidcConfigHandle(par = true)

        val config = OidcClientConfig().apply { applyHandle(handle) }

        assertEquals(true, config.par)
    }

    @Test
    fun `hasOidcConfig returns true when only oidcClientId is set`() {
        val config = JourneyConfigMessage(serverUrl = "https://example.com/am", oidcClientId = "any-id")

        assertTrue(JourneyConfigParser.hasOidcConfig(config))
    }

    @Test
    fun `hasOidcConfig returns true for the existing inline-only path`() {
        val config = JourneyConfigMessage(serverUrl = "https://example.com/am", clientId = "client-1")

        assertTrue(JourneyConfigParser.hasOidcConfig(config))
    }

    @Test
    fun `hasOidcConfig returns false when neither oidcClientId nor inline fields are set`() {
        val config = JourneyConfigMessage(serverUrl = "https://example.com/am")

        assertFalse(JourneyConfigParser.hasOidcConfig(config))
    }
}
