/*
 * ping-sample-web-angular-davinci
 *
 * create-config.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { environment } from '../environments/environment.js';

/**
 * @function createConfig - Gets the configuration object for both the Javascript SDK and DaVinci client
 * @returns {Object}
 */
export default function createConfig() {
  const config = {
    clientId: environment.WEB_OAUTH_CLIENT,
    redirectUri: `${window.location.origin}/callback.html`,
    scope: environment.SCOPE,
    serverConfig: {
      wellknown: environment.WELLKNOWN_URL,
      timeout: 3000,
    },
  };
  return config;
}
