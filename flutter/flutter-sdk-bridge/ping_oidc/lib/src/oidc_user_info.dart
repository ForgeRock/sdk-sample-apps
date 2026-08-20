/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/// The claims returned by [OidcClient.userInfo], as decoded from the ID provider's userinfo
/// endpoint. Deliberately a plain map, not a typed wrapper — the server doesn't guarantee a fixed
/// claim set (custom claims, provider-specific extensions), and inventing a partial wrapper type
/// would either drop unknown claims silently or require constant maintenance to keep pace with
/// claims this module has no way to enumerate. Use `info['sub']`, `info['email']`, etc. directly.
typedef OidcUserInfo = Map<String, Object?>;
