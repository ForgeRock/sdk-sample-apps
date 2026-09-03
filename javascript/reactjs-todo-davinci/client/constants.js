/*
 * ping-sample-web-react-davinci
 *
 * constants.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the DaVinci and OIDC clients
 * ----------------------------------------------------------------------------
 * Details: There are two ways to initialize the SDK clients. Option 1 is to
 * provide the configuration values from `.env` directly to the clients.
 * Option 2 is to use the JSON configuration from `config.json` which is
 * supported across all platforms. Both options are demonstrated below.
 *
 * Using `config.json` is optional. If you prefer, you can continue supplying
 * the SDK configuration via the `SDK_<NAME>` environment variables. The
 * app falls back to `config.json` only when these are not set.
 *************************************************************************** */
import sdkConfig from '../config.json';
import { makeDavinciConfig, makeOidcConfig } from '@forgerock/sdk-utilities';

// Application-specific variables
export const API_URL = process.env.API_URL;
export const DEBUGGER = process.env.DEBUGGER_OFF === 'false'; // Yes, the debugger boolean is intentionally reversed
export const INIT_PROTECT = process.env.INIT_PROTECT;
export const PINGONE_ENV_ID = process.env.PINGONE_ENV_ID;

const CLIENT_ID = process.env.SDK_CLIENT_ID;
const DISCOVERY_ENDPOINT = process.env.SDK_DISCOVERY_ENDPOINT;
const SCOPE = process.env.SDK_SCOPE;

/** ***************************************************************************
 * Option 1: Get the config from SDK_<NAME> variables `.env`
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
export const DAVINCI_CONFIG = envConfig ?? makeDavinciConfig(jsonConfig);
export const OIDC_CONFIG = envConfig ?? makeOidcConfig(jsonConfig);
