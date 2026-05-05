/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


package com.example.app

import kotlinx.serialization.Serializable
import org.forgerock.android.auth.FROptions
import org.forgerock.android.auth.FROptionsBuilder

/**
 * PingConfig to handle the configuration.
 * @property discoveryEndpoint String the discovery endpoint.
 * @property oauthClientId String the oauth client id.
 * @property oauthRedirectUri String the oauth redirect uri.
 * @property oauthSignOutRedirectUri String the oauth sign out redirect uri.
 * @property cookieName String the cookie name.
 * @property oauthScope String the oauth scope.
 */
@Serializable
data class PingConfig(
    var discoveryEndpoint: String = "", // Add the discovery endpoint of your server
    var oauthClientId: String = "", // Add the client id of the OAuth2.0 client used by the app
    var oauthRedirectUri: String = "org.forgerock.demo:/oauth2redirect", // Configure the redirect URI to the one selected in the app
    var oauthSignOutRedirectUri: String = "", // Configure the sign out redirect URI to the one selected in the app, if needed.
    var cookieName: String = "", // Configure the cookie name of your AIC/AM environment
    var oauthScope: String = "") // Configure the OAuth2.0 scopes in a space separated string. ex: "openid email profile"

/**
 * Convert PingConfig to FROptions.
 */
fun PingConfig.toFROptions(): FROptions {
    return FROptionsBuilder.build {
        server {
            url = this@toFROptions.discoveryEndpoint
            this@toFROptions.cookieName.takeIf { it.isNotEmpty() }?.let { cookieName = it }
        }
        oauth {
            oauthClientId = this@toFROptions.oauthClientId
            oauthRedirectUri = this@toFROptions.oauthRedirectUri
            this@toFROptions.oauthSignOutRedirectUri.takeIf { it.isNotEmpty() }?.let { oauthSignOutRedirectUri = it }
            oauthScope = this@toFROptions.oauthScope
        }
    }
}

