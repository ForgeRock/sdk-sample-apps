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
 * Summary: Configure the DaVinci client
 * ----------------------------------------------------------------------------
 * Details: CONFIG uses the unified SDK configuration schema. Pass it to
 * `makeDavinciConfig(CONFIG)` from `@forgerock/sdk-utilities` before calling
 * the factory — e.g. `davinci({ config: makeDavinciConfig(CONFIG) })`.
 *
 * Local dev: copy config.example.json → config.json and fill in your values.
 * E2e / CI: set SDK_CONFIG to a JSON string (e.g. from config.test.json).
 *************************************************************************** */
import sdkConfigJson from '../config.json';
export const API_URL = process.env.API_URL;
// Yes, the debugger boolean is intentionally reversed
export const DEBUGGER = process.env.DEBUGGER_OFF === 'false';
export const INIT_PROTECT = process.env.INIT_PROTECT;
export const PINGONE_ENV_ID = process.env.PINGONE_ENV_ID;

const rawConfig = (() => {
  if (!process.env.SDK_CONFIG) {
    return sdkConfigJson;
  }
  try {
    return JSON.parse(process.env.SDK_CONFIG);
  } catch (error) {
    throw new Error(`Invalid SDK_CONFIG JSON: ${error.message}`);
  }
})();

export const CONFIG = {
  ...rawConfig,
  oidc: {
    ...rawConfig.oidc,
    redirectUri: `${window.location.origin}/callback.html`,
  },
};
