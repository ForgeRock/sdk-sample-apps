/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.samples.oidc.app.rar

import com.pingidentity.logger.Logger
import com.pingidentity.logger.STANDARD
import com.pingidentity.oidc.AuthorizationDetail
import com.pingidentity.oidc.OidcWebClient
import com.pingidentity.oidc.module.Oidc

/**
 * The client settings that are fixed when a Rich Authorization Requests (RFC 9396) client
 * is built: `par` and the config-level [authorizationDetails].
 */
data class RarClientOptions(
    val par: Boolean = false,
    val authorizationDetails: List<AuthorizationDetail>? = null,
)

/**
 * Owns the OIDC Web client used for Rich Authorization Requests (RFC 9396).
 *
 * `par` and the config-level `authorizationDetails` are fixed when a client is built, so
 * changing them builds a new client; [apply] keeps the current client while the options are
 * unchanged. `par` is on `OidcClientConfig`, so it can only be set at client build time — the
 * store rebuilds the client instead of mutating it.
 *
 * The client keeps its token in its own storage file ([STORAGE_FILE_NAME]), separate from the
 * standard `web` client: starting an authorization revokes and replaces the token held in the
 * storage of the client that starts it, so a shared storage would let a RAR authorization
 * revoke the standard token (and vice versa). A rebuilt client reads the same persisted file,
 * so the token survives both a rebuild and an app relaunch.
 */
object RarClientStore {

    /** The DataStore file that holds the RAR token, kept apart from the default token file. */
    const val STORAGE_FILE_NAME = "ACCESS_TOKEN_STORAGE_RAR"

    /** The client for the current [options]. */
    var client: OidcWebClient = makeClient(RarClientOptions())
        private set

    /** The options the current [client] was built with. */
    var options: RarClientOptions = RarClientOptions()
        private set

    /**
     * Makes [options] current, building a new client only when they differ from the current
     * ones. A no-op while the options are equal, so repeated logins with the same settings
     * reuse the client (and its persisted token).
     */
    fun apply(options: RarClientOptions) {
        if (options == this.options) return
        client = makeClient(options)
        this.options = options
    }

    /**
     * Builds a client that authenticates as the RAR OAuth 2.0 client, keeps its token in
     * [STORAGE_FILE_NAME], and applies [options].
     */
    private fun makeClient(options: RarClientOptions): OidcWebClient =
        OidcWebClient {
            logger = Logger.STANDARD
            module(Oidc) {
                clientId = "rarClientVibhor"
                discoveryEndpoint = "https://openam-sdks.forgeblocks.com/am/oauth2/alpha/.well-known/openid-configuration"
                scopes = mutableSetOf("openid", "profile")
                redirectUri = "org.forgerock.demo:/oauth2redirect"
                par = options.par
                authorizationDetails = options.authorizationDetails.orEmpty()
                storage {
                    fileName = STORAGE_FILE_NAME
                }
            }
        }
}
