/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// Stable `PigeonError.code` per bridge operation.
enum OidcErrorCodes {
    static let configure = "OIDC_CONFIGURE_ERROR"
    static let dispose = "OIDC_DISPOSE_ERROR"
    static let createWebClient = "OIDC_CREATE_WEB_CLIENT_ERROR"
    static let authorize = "OIDC_AUTHORIZE_ERROR"
    static let hasUser = "OIDC_HAS_USER_ERROR"
    static let token = "OIDC_TOKEN_ERROR"
    static let refresh = "OIDC_REFRESH_ERROR"
    static let userInfo = "OIDC_USERINFO_ERROR"
    static let revoke = "OIDC_REVOKE_ERROR"
    static let signOff = "OIDC_LOGOUT_ERROR"
}
