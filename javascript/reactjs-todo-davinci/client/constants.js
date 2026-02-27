/*
 * ping-sample-web-react-davinci
 *
 * constants.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export const API_URL = process.env.API_URL;
// Yes, the debugger boolean is intentionally reversed
export const DEBUGGER = process.env.DEBUGGER_OFF === 'false';
export const WEB_OAUTH_CLIENT = process.env.WEB_OAUTH_CLIENT;
export const SCOPE = process.env.SCOPE;
export const WELLKNOWN_URL = process.env.WELLKNOWN_URL;
export const INIT_PROTECT = process.env.INIT_PROTECT;
export const PINGONE_ENV_ID = process.env.PINGONE_ENV_ID;
/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the OIDC client
 * ----------------------------------------------------------------------------
 * Details: The config object below is passed to the `oidc()` initializer in
 * `oidc.context.js` to configure the OIDC client:
 * - clientId: the OAuth 2.0 client ID registered in PingOne
 * - redirectUri: the URI of this app to which the OAuth 2.0 flow redirects
 *   after authentication (points to callback.html for the redirect handler)
 * - scope: the OAuth 2.0 scopes requested from PingOne
 * - serverConfig.wellknown: the OpenID Connect discovery URL for your
 *   PingOne environment, used to resolve authorization/token endpoints
 *************************************************************************** */
export const CONFIG = {
  clientId: WEB_OAUTH_CLIENT,
  redirectUri: `${window.location.origin}/callback.html`,
  scope: SCOPE,
  serverConfig: {
    wellknown: WELLKNOWN_URL,
  },
};
