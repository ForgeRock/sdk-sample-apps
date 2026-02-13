/*
 * ping-sample-web-react-davinci
 *
 * request.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { API_URL, DEBUGGER } from '../constants';

/**
 * @function request - A convenience function for making authenticated API requests
 * @param {string} resource - the resource path for the API server
 * @param {string} method - the method (GET, POST, etc) for the API server
 * @param {string} data - the data to POST against the API server
 * @param {Object} oidcClient - the OIDC client instance
 * @return {Object} - JSON response from API
 */
export default async function apiRequest(resource, method, data, oidcClient) {
  let json;
  try {
    /** ***********************************************************************
     * SDK INTEGRATION POINT
     * Summary: Native fetch for protected resource server requests.
     * ------------------------------------------------------------------------
     * Details: This helper accepts an OIDC client instance, retrieves the
     * access token via oidcClient.token.get(), and adds it to the authorization
     * header as a bearer token for making HTTP requests to protected resource
     * APIs.
     *********************************************************************** */
    if (DEBUGGER) debugger;
    const tokens = await oidcClient.token.get();
    if ('error' in tokens) {
      throw new Error(tokens.error);
    }

    const init = {
      headers: {
        'Content-Type': 'application/json',
        ...(tokens?.accessToken ? { Authorization: `Bearer ${tokens.accessToken}` } : {}),
      },
      method,
      ...(data ? { body: JSON.stringify(data) } : {}),
    };

    const fetchPromise = fetch(`${API_URL}/${resource}`, init);
    const timeout = new Promise((resolve, reject) =>
      setTimeout(() => reject(new Error('Request timed out')), 5000),
    );

    const response = await Promise.race([fetchPromise, timeout]);
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
