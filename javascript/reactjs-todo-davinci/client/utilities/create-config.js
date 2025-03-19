/*
 * ping-sample-web-react-davinci
 *
 * create-config.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { WEB_OAUTH_CLIENT, SCOPE, WELLKNOWN_URL } from '../constants.js';

/**
 * @function createConfig - Gets the configuration object for both the Javascript SDK and DaVinci client
 * @returns {Object}
 */
export default function createConfig() {
  const config = {
    clientId: WEB_OAUTH_CLIENT,
    redirectUri: `${window.location.origin}/callback.html`,
    scope: SCOPE,
    serverConfig: {
      wellknown: WELLKNOWN_URL,
    },
  };
  return config;
}
