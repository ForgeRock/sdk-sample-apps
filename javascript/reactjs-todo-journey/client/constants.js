/*
 * ping-sample-web-react-journey
 *
 * constants.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

export const API_URL = import.meta.env.VITE_API_URL;
// Yes, the debugger boolean is intentionally reversed
export const DEBUGGER = import.meta.env.VITE_DEBUGGER_OFF === 'false';
export const JOURNEY_LOGIN = import.meta.env.VITE_JOURNEY_LOGIN;
export const JOURNEY_REGISTER = import.meta.env.VITE_JOURNEY_REGISTER;
export const INIT_PROTECT = import.meta.env.VITE_INIT_PROTECT;
export const PINGONE_ENV_ID = import.meta.env.VITE_PINGONE_ENV_ID;
/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the SDK
 * ----------------------------------------------------------------------------
 * Details: CONFIG uses the unified SDK configuration schema. Pass it to
 * `makeOidcConfig(CONFIG)` or `makeJourneyConfig(CONFIG)` from
 * `@forgerock/sdk-utilities` before calling the respective factory.
 *
 * Local dev: copy config.example.json → config.json and fill in your values.
 * E2e / CI: set VITE_SDK_CONFIG to a JSON string (e.g. from config.test.json).
 *************************************************************************** */
import sdkConfigJson from '../config.json';

const rawConfig = (() => {
  if (!import.meta.env.VITE_SDK_CONFIG) {
    return sdkConfigJson;
  }
  try {
    return JSON.parse(import.meta.env.VITE_SDK_CONFIG);
  } catch (error) {
    throw new Error(`Invalid VITE_SDK_CONFIG JSON: ${error.message}`);
  }
})();

export const CONFIG = {
  ...rawConfig,
  oidc: {
    ...rawConfig.oidc,
    redirectUri: rawConfig.oidc?.redirectUri ?? `${window.location.origin}/callback.html`,
  },
};
