/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.davinci

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
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Test-local [OidcConfigHandle], registered straight into [CoreRuntime.oidcClientRegistry]. */
private class FakeOidcConfigHandle(
    override val clientId: String = "client-1",
    override val discoveryEndpoint: String? = "https://example.com/.well-known/openid-configuration",
    override val openId: OidcOpenIdConfig? = null,
    override val redirectUri: String? = "com.example://callback",
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

private fun hoisted() =
    DaVinciConfigMessage(
        clientId = "client",
        redirectUri = "com.example://callback",
        discoveryEndpoint = "https://example.com/.well-known/openid-configuration",
    )

/**
 * Unit tests for the DaVinci config parser.
 *
 * These call [validate], [applyMessage] and [applyHandle] directly rather than through
 * [DaVinciConfigParser.parse]: the native `DaVinci { }` builder reads
 * `android.os.LocaleList.getDefault()`, which the stub `android.jar` can't satisfy on the JVM.
 */
class DaVinciConfigParserTest {
    private val registeredIds = mutableListOf<String>()

    private fun register(handle: FakeOidcConfigHandle): String =
        CoreRuntime.oidcClientRegistry.register(handle).also { registeredIds.add(it) }

    @AfterTest
    fun cleanUp() {
        registeredIds.forEach { CoreRuntime.oidcClientRegistry.remove(it) }
        registeredIds.clear()
    }

    @Test
    fun `validate accepts a complete hoisted config`() {
        validate(hoisted())
    }

    @Test
    fun `validate accepts an openId-only hoisted config`() {
        validate(
            hoisted().copy(
                discoveryEndpoint = null,
                openId = OpenIdConfigMessage("https://a", "https://t", "https://u"),
            )
        )
    }

    @Test
    fun `validate accepts oidcClientId alone`() {
        validate(DaVinciConfigMessage(oidcClientId = "some-id"))
    }

    @Test
    fun `validate rejects oidcClientId combined with any inline field`() {
        val inline =
            listOf(
                DaVinciConfigMessage(clientId = "c"),
                DaVinciConfigMessage(acrValues = "flow"),
                DaVinciConfigMessage(par = false),
                DaVinciConfigMessage(additionalParameters = mapOf("k" to "v")),
            )
        inline.forEach { config ->
            assertFailsWith<IllegalArgumentException> {
                validate(config.copy(oidcClientId = "some-id"))
            }
        }
    }

    @Test
    fun `validate rejects a config with neither discoveryEndpoint nor openId`() {
        val error =
            assertFailsWith<IllegalArgumentException> {
                validate(hoisted().copy(discoveryEndpoint = null))
            }
        assertEquals("DaVinciConfigMessage requires discoveryEndpoint or openId.", error.message)
        assertFailsWith<IllegalArgumentException> {
            validate(hoisted().copy(discoveryEndpoint = "  "))
        }
    }

    @Test
    fun `validate rejects a config with no OIDC at all`() {
        assertFailsWith<IllegalArgumentException> { validate(DaVinciConfigMessage()) }
    }

    @Test
    fun `validate rejects a missing redirectUri`() {
        assertFailsWith<IllegalArgumentException> {
            validate(hoisted().copy(redirectUri = null))
        }
    }

    @Test
    fun `hasInlineOidcFields is false for an empty config`() {
        assertFalse(hasInlineOidcFields(DaVinciConfigMessage(timeoutMillis = 1, oidcClientId = "x")))
        assertTrue(hasInlineOidcFields(DaVinciConfigMessage(prompt = "login")))
    }

    @Test
    fun `applyMessage maps every hoisted field`() {
        val config = OidcClientConfig()
        config.applyMessage(
            hoisted().copy(
                scopes = listOf("openid", null, "email"),
                acrValues = "flow-acr",
                signOutRedirectUri = "com.example://logout",
                state = "s",
                nonce = "n",
                uiLocales = "en",
                refreshThreshold = 60,
                loginHint = "user",
                display = "page",
                prompt = "login",
                additionalParameters = mapOf("k" to "v", "drop" to null),
                par = true,
            )
        )

        assertEquals("client", config.clientId)
        assertEquals("com.example://callback", config.redirectUri)
        assertEquals("https://example.com/.well-known/openid-configuration", config.discoveryEndpoint)
        assertEquals(setOf("openid", "email"), config.scopes)
        assertEquals("flow-acr", config.acrValues)
        assertEquals("com.example://logout", config.signOutRedirectUri)
        assertEquals("s", config.state)
        assertEquals("n", config.nonce)
        assertEquals("en", config.uiLocales)
        assertEquals(60L, config.refreshThreshold)
        assertEquals("user", config.loginHint)
        assertEquals("page", config.display)
        assertEquals("login", config.prompt)
        assertEquals(mapOf("k" to "v"), config.additionalParameters)
        assertTrue(config.par)
    }

    @Test
    fun `applyMessage with openId only sets openId and a blank discoveryEndpoint`() {
        val config = OidcClientConfig()
        config.applyMessage(
            hoisted().copy(
                discoveryEndpoint = null,
                openId = OpenIdConfigMessage("https://a", "https://t", "https://u"),
            )
        )

        // The blank discoveryEndpoint works around the SDK's clone() lateinit bug.
        assertEquals("", config.discoveryEndpoint)
        assertEquals("https://t", config.openId.tokenEndpoint)
        assertNull(config.openIdOverride)
    }

    @Test
    fun `applyMessage with discoveryEndpoint and openId patches the discovered document`() {
        val config = OidcClientConfig()
        config.applyMessage(
            hoisted().copy(openId = OpenIdConfigMessage("https://a", "https://t", "https://u"))
        )

        assertNotNull(config.openIdOverride)
    }

    @Test
    fun `resolveOidcHandle rejects an unknown id`() {
        assertFailsWith<IllegalArgumentException> { resolveOidcHandle("no-such-id") }
    }

    @Test
    fun `resolveOidcHandle rejects a handle with no endpoint`() {
        val id = register(FakeOidcConfigHandle(discoveryEndpoint = null))
        assertFailsWith<IllegalArgumentException> { resolveOidcHandle(id) }
    }

    @Test
    fun `applyHandle maps the handle's fields`() {
        val id = register(FakeOidcConfigHandle(clientId = "client-42", acrValues = "acr", par = true))
        val config = OidcClientConfig()

        config.applyHandle(resolveOidcHandle(id))

        assertEquals("client-42", config.clientId)
        assertEquals("acr", config.acrValues)
        assertEquals(setOf("openid", "profile"), config.scopes)
        assertTrue(config.par)
    }
}
