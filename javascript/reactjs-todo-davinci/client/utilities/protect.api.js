/*
 * ping-sample-web-react-davinci
 *
 * protect.api.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { protect } from '@forgerock/protect';

let protectApi;

/**
 * @function getProtectApi - Gets the PingOne Protect API if it exists
 * @returns {Object} - A set of methods for interacting with PingOne Protect
 */
export function getProtectApi() {
  if (!protectApi) {
    throw new Error('Protect API is not initialized');
  }

  return protectApi;
}

/**
 * @function initProtectApi - Initializes the PingOne Protect API with the provided configuration
 * @param {Object} config - Configuration object for Protect
 * @returns {Object} - A set of methods for interacting with PingOne Protect
 */
export function initProtectApi(config) {
  if (!config) {
    throw new Error('Protect configuration is required');
  }

  if (protectApi) {
    return protectApi;
  } else {
    protectApi = protect(config);
    return protectApi;
  }
}
