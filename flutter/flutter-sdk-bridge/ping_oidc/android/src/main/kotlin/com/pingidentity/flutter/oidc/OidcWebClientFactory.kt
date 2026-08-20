/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc

import com.pingidentity.flutter.core.CoreRuntime
import com.pingidentity.flutter.core.registry.NativeHandle
import com.pingidentity.oidc.OidcWebClient
import com.pingidentity.oidc.module.Oidc

/**
 * Wraps a live native [OidcWebClient] so it can be stored in
 * [CoreRuntime.oidcWebClientRegistry]. Unlike [OidcClientHandle], this handle doesn't implement
 * `ping_core`'s `OidcConfigHandle` — the config-handle contract is served by the client handle
 * that [create] resolves from, not by the web client itself.
 */
internal class OidcWebClientHandle(val webClient: OidcWebClient) : NativeHandle

/**
 * Builds a native [OidcWebClient] from the flat payload of an already-registered
 * [OidcClientHandle] and registers it in [CoreRuntime.oidcWebClientRegistry].
 *
 * The web client is built fresh from [OidcClientHandle.payload] rather than reusing
 * [OidcClientHandle.client] — neither native SDK's web-client config supports wrapping/cloning a
 * live client (confirmed by reading `OidcWebClient.kt`/`OidcWebClientConfig`: it's a bare
 * `WorkflowConfig` unrelated to `OidcClientConfig`, built only via `module(Oidc) { }`).
 *
 * [BrowserOptionsMessage] is intentionally unused here — Android only has Chrome Custom Tabs, no
 * `BrowserType`/`BrowserMode` equivalent to apply.
 */
internal object OidcWebClientFactory {
    fun create(clientHandleId: String, options: BrowserOptionsMessage?): String {
        val handle =
            (CoreRuntime.oidcClientRegistry.resolve(clientHandleId) as? OidcClientHandle)
                ?: throw IllegalStateException(
                    "OIDC client instance not found for id=$clientHandleId"
                )
        val webClient = OidcWebClient { module(Oidc) { applyMessage(handle.payload) } }
        return CoreRuntime.oidcWebClientRegistry.register(OidcWebClientHandle(webClient))
    }
}
