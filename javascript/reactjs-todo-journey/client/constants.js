/*
 * ping-sample-web-react-journey
 *
 * constants.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

const urlParams = new URLSearchParams(window.location.search);
const centralLoginParam = urlParams.get('centralLogin');

export const SERVER_URL = import.meta.env.VITE_SERVER_URL;
export const API_URL = import.meta.env.VITE_API_URL;
// Yes, the debugger boolean is intentionally reversed
export const DEBUGGER = import.meta.env.VITE_DEBUGGER_OFF === 'false';
export const JOURNEY_LOGIN = import.meta.env.VITE_JOURNEY_LOGIN;
export const JOURNEY_REGISTER = import.meta.env.VITE_JOURNEY_REGISTER;
export const WEB_OAUTH_CLIENT = import.meta.env.VITE_WEB_OAUTH_CLIENT;
export const REALM_PATH = import.meta.env.VITE_REALM_PATH;
export const CENTRALIZED_LOGIN = import.meta.env.VITE_CENTRALIZED_LOGIN;
export const SESSION_URL = `${SERVER_URL}json/realms/root/sessions`;
export const SCOPE = import.meta.env.VITE_SCOPE;
export const WELLKNOWN_URL = import.meta.env.VITE_WELLKNOWN_URL;
export const INIT_PROTECT = import.meta.env.VITE_INIT_PROTECT;
export const PINGONE_ENV_ID = import.meta.env.VITE_PINGONE_ENV_ID;

const redirectUri = `${window.location.origin}/${
  CENTRALIZED_LOGIN === 'true' || centralLoginParam === 'true'
    ? 'login?centralLogin=true'
    : 'callback.html'
}`;

/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the SDK
 * ----------------------------------------------------------------------------
 * Details: Below, you will see the following settings which can be used to
 * configure both the OIDC and Journey clients:
 * - clientId: (OAuth 2.0 only) this is the OAuth 2.0 client you created in Ping,
 *   such as `PingSDKClient`
 * - redirectUri: (OAuth 2.0 only) this is the URI/URL of this app to which the
 *   OAuth 2.0 flow redirects
 * - scope: (OAuth 2.0 only) these are the OAuth scopes that you will request from
 *   Ping
 * - serverConfig: this includes the wellknown URL of your Ping client
 * - realmPath: this is the realm to use within Ping, such as `alpha` or `root`
 *************************************************************************** */
export const CONFIG = {
  clientId: WEB_OAUTH_CLIENT,
  redirectUri,
  scope: SCOPE,
  serverConfig: {
    wellknown: WELLKNOWN_URL,
  },
  realmPath: REALM_PATH,
};
