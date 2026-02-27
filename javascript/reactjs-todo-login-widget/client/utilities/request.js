/*
 * forgerock-sample-web-react
 *
 * request.js
 *
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { request } from '@forgerock/login-widget';

import { API_URL, DEBUGGER } from '../constants';

/**
 * @function request - A convenience function for wrapping around HttpClient
 * @param {string} resource - the resource path for the API server
 * @param {string} method - the method (GET, POST, etc) for the API server
 * @param {string} data - the data to POST against the API server
 * @return {Object} - JSON response from API
 */
export default async function apiRequest(resource, method, data) {
  let json;
  try {
    /** ***********************************************************************
     * LOGIN WIDGET INTEGRATION POINT
     * Summary: Request for protected resource server requests.
     * ------------------------------------------------------------------------
     * Details: The Ping Login Widget has an alias to the Ping SDK for
     * JavaScript’s HttpClient.request method, which is a convenience wrapper
     * around the native fetch. This method will auto-inject the access token
     * into the Authorization header and manage some of the lifecycle around
     * the token.
     *********************************************************************** */
    if (DEBUGGER) debugger;
    const response = await request({
      url: `${API_URL}/${resource}`,
      init: {
        body: data && JSON.stringify(data),
        headers: {
          'Content-Type': 'application/json',
        },
        method,
      },
    });
    if (!response.ok) {
      throw new Error(`Status ${response.status}: API request failed`);
    }
    json = await response.json();
  } catch (err) {
    console.error(`Error: API request; ${err}`);

    json = {
      error: err.message,
    };
  }

  return json;
}
