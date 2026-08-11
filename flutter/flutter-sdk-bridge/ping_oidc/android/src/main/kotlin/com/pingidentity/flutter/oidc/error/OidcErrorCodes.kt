/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

package com.pingidentity.flutter.oidc.error

/** Stable per-operation error codes surfaced to Dart as `PingException.code`. */
internal object OidcErrorCodes {
    const val CONFIGURE = "OIDC_CONFIGURE_ERROR"
    const val DISPOSE = "OIDC_DISPOSE_ERROR"
    const val CREATE_WEB_CLIENT = "OIDC_CREATE_WEB_CLIENT_ERROR"
    const val AUTHORIZE = "OIDC_AUTHORIZE_ERROR"
    const val HAS_USER = "OIDC_HAS_USER_ERROR"
    const val TOKEN = "OIDC_TOKEN_ERROR"
    const val REFRESH = "OIDC_REFRESH_ERROR"
    const val USERINFO = "OIDC_USERINFO_ERROR"
    const val REVOKE = "OIDC_REVOKE_ERROR"
    const val SIGN_OFF = "OIDC_LOGOUT_ERROR"
}
