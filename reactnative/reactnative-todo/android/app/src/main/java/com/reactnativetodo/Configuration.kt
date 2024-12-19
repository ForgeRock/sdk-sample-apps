/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.reactnativetodo


/**
 * Configuration class for the ForgeRock SDK.
 */
data class Configuration(
    /** The main authentication journey name.  */
    val mainAuthenticationJourney: String = "jey-webAuthn",

    /** The URL of the authentication server.  */
    val amURL: String = "https://openam-sdks.forgeblocks.com/am",

    /** The name of the cookie used for authentication.  */
    val cookieName: String = "5421aeddf91aa20",

    /** The realm used for authentication.  */
    val realm: String = "alpha",

    /** The OAuth client ID.  */
    val oauthClientId: String = "AndroidTest",

    /** The OAuth redirect URI.  */
    val oauthRedirectURI: String = "org.forgerock.demo:/oauth2redirect",

    /** The OAuth scopes.  */
    val oauthScopes: String = "openid profile email address phone",

    /** The discovery endpoint for OAuth configuration.  */
    val discoveryEndpoint: String = "[DISCOVERY_ENDPOINT]",

    val registrationServiceName: String = "Registration",
)
