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
    val mainAuthenticationJourney: String = "[YOUR_MAIN_AUTHENTICATION_JOURNEY_NAME]",

    /** The URL of the authentication server.  */
    val amURL: String = "[YOUR_AM_URL]",

    /** The name of the cookie used for authentication.  */
    val cookieName: String = "[COOKIE NAME]",

    /** The realm used for authentication.  */
    val realm: String = "[REALM NAME]",

    /** The OAuth client ID.  */
    val oauthClientId: String = "[OAUTH_CLIENT_ID]",

    /** The OAuth redirect URI.  */
    val oauthRedirectURI: String = "[OAUTH_REDIRECT_URI]",

    /** The OAuth scopes.  */
    val oauthScopes: String = "[OAUTH_SCOPES]",

    /** The discovery endpoint for OAuth configuration.  */
    val discoveryEndpoint: String = "[DISCOVERY_ENDPOINT]",

    val registrationServiceName: String = "Registration",
)
