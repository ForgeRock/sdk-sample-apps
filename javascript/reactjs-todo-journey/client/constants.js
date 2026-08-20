/*
 * ping-sample-web-react-journey
 *
 * constants.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import sdkConfig from '../config.json';
import { makeJourneyConfig, makeOidcConfig } from '@forgerock/sdk-utilities';

// Application-specific variables
export const API_URL = import.meta.env.VITE_API_URL;
export const DEBUGGER = import.meta.env.VITE_DEBUGGER_OFF === 'false'; // Yes, the debugger boolean is intentionally reversed
export const JOURNEY_LOGIN = import.meta.env.VITE_JOURNEY_LOGIN;
export const JOURNEY_REGISTER = import.meta.env.VITE_JOURNEY_REGISTER;
export const INIT_PROTECT = import.meta.env.VITE_INIT_PROTECT;
export const PINGONE_ENV_ID = import.meta.env.VITE_PINGONE_ENV_ID;

/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the SDK
 * ----------------------------------------------------------------------------
 * Details: There are two ways to initialize the SDK clients. Option 1 is to
 * provide the configuration values from `.env` directly to the clients.
 * Option 2 is to use the JSON configuration from `config.json` which is
 * supported across all platforms. Both options are demonstrated below.
 *
 * Using `config.json` is optional. If you prefer, you can continue supplying
 * the SDK configuration via the `VITE_SDK_<NAME>` environment variables. The
 * app falls back to `config.json` only when these are not set.
 *************************************************************************** */
const CLIENT_ID = import.meta.env.VITE_SDK_CLIENT_ID;
const DISCOVERY_ENDPOINT = import.meta.env.VITE_SDK_DISCOVERY_ENDPOINT;
const SCOPE = import.meta.env.VITE_SDK_SCOPE;

/** ***************************************************************************
 * Option 1: Get the config from VITE_SDK_<NAME> variables `.env`
 * ----------------------------------------------------------------------------
 * Below, you will see the following settings which can be used to
 * configure both the OIDC and Journey clients:
 *
 * - clientId: (OAuth 2.0 only) this is the OAuth 2.0 client you created in Ping,
 *   such as `PingSDKClient`
 * - redirectUri: (OAuth 2.0 only) this is the URI/URL of this app to which the
 *   OAuth 2.0 flow redirects
 * - scope: (OAuth 2.0 only) these are the OAuth scopes that you will request from
 *   Ping
 * - serverConfig: this includes the wellknown URL of your Ping client
 *************************************************************************** */
const envConfig =
  !CLIENT_ID || !DISCOVERY_ENDPOINT || !SCOPE
    ? null
    : {
        clientId: CLIENT_ID,
        scope: SCOPE,
        serverConfig: {
          wellknown: DISCOVERY_ENDPOINT,
        },
        redirectUri: `${window.location.origin}/callback.html`,
      };

/** ***************************************************************************
 * Option 2: Use the unified JSON config from `config.json` to create
 * configuration objects.
 *************************************************************************** */
const jsonConfig = sdkConfig
  ? {
      ...sdkConfig,
      oidc: {
        ...sdkConfig.oidc,
        redirectUri: sdkConfig.oidc?.redirectUri ?? `${window.location.origin}/callback.html`,
      },
    }
  : null;

// SDK-specific variables
export const JOURNEY_CONFIG = envConfig ?? makeJourneyConfig(jsonConfig);
export const OIDC_CONFIG = envConfig ?? makeOidcConfig(jsonConfig);
