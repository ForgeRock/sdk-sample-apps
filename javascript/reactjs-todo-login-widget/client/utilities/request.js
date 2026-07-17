/*
 * forgerock-sample-web-react
 *
 * request.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { user } from '@forgerock/login-widget';

import { API_URL, DEBUGGER } from '../constants';

/**
 * @function request - A convenience function for wrapping around fetch with auth
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
     * Details: This helper retrieves your access token via user.tokens().get()
     * and adds it to the Authorization header as a bearer token for making
     * HTTP requests to protected resource APIs.
     *********************************************************************** */
    if (DEBUGGER) debugger;
    const tokenEvents = user.tokens();
    const { response: tokens } = await tokenEvents.get();
    if (!tokens?.accessToken) {
      throw new Error('Failed to retrieve access token');
    }

    const request = fetch(`${API_URL}/${resource}`, {
      body: data && JSON.stringify(data),
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${tokens.accessToken}`,
      },
      method,
    });
    const timeout = new Promise((_resolve, reject) =>
      setTimeout(() => reject(new Error('Request timed out')), 5000),
    );
    const response = await Promise.race([request, timeout]);
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
