/*
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */


import { NativeModules } from 'react-native';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { API_PORT, API_BASE_URL, DEBUGGER_OFF } from '../../.env';

if (!API_BASE_URL) {
  console.error('*************** MISSING API URL *************');
  console.error('*************** CHECK .ENV.JS FILE IN ROOT *************');
  throw new Error('MISSING ENV VARIABLES, SEE .env.js FILE');
}

const { FRAuthSampleBridge } = NativeModules;

/**
 * @function request - request utility method for calling protected APIs
 * @param {string} method - GET, POST, PUT, DELETE
 * @param {string} path - The path NOT including the origin or beginning slash
 * @param {*} body - The object to POST to server
 * @returns {*} - Object from response body
 */
export default async function request(method, path = '', body = null) {
  try {
    /*****************************************************************
     * NATIVE BRIDGE SDK INTEGRATION POINT
     * Summary: Requesting access token to make protected request
     * ------------------------------------------------------------------
     * Details: Here we are checking for an existing access token in
     * order to make a request for a protected resource.
     *  *************************************************************** */
    if (!DEBUGGER_OFF) debugger;
    const json = await FRAuthSampleBridge.getAccessToken();
    const tokens = JSON.parse(json);
    const { tokenType, value } = tokens;

    const apiEndpoint = `${API_BASE_URL}${
      API_PORT ? `:${API_PORT}` : ``
    }/${path}`;

    console.log(`${method} ${apiEndpoint}`);

    const res = await fetch(apiEndpoint, {
      method,
      body: body && JSON.stringify(body),
      headers: {
        'Content-Type': 'application/json',
        authorization: `${tokenType} ${value}`,
      },
    });

    if (method === 'DELETE') return;
    if (!res.ok) throw new Error(`Status ${res.status}: API request failed`);
    const response = await res.json();

    return response;
  } catch (err) {
    throw new Error('Error: API called failed.');
  }
}
