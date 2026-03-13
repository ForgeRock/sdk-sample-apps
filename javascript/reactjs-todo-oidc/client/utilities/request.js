/*
 * ping-sample-web-react-todo-oidc
 *
 * request.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { API_URL, DEBUGGER } from '../constants';

/**
 * @function apiRequest - A convenience function for authenticated API requests
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
     * access token and adds it to the authorization header as a bearer token
     * for making HTTP requests to protected resource APIs.
     *********************************************************************** */
    if (DEBUGGER) debugger;
    if (!oidcClient) {
      throw new Error('OIDC client is not initialized');
    }

    const tokens = await oidcClient.token.get();
    if ('error' in tokens) {
      throw new Error(tokens.error);
    }

    const response = await fetch(`${API_URL}/${resource}`, {
      headers: {
        'Content-Type': 'application/json',
        ...(tokens?.accessToken ? { Authorization: `Bearer ${tokens.accessToken}` } : {}),
      },
      method,
      ...(data ? { body: JSON.stringify(data) } : {}),
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
