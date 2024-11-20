/*
 * forgerock-sample-web-react
 *
 * constants.mjs
 *
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Buffer } from 'buffer';

export const SERVER_URL = (() => {
  try {
    const lastChar = process.env.SERVER_URL.slice(-1);
    if (lastChar !== '/') {
      return process.env.SERVER_URL + '/';
    }
    return process.env.SERVER_URL;
  } catch (err) {
    console.error(
      'AM * ERROR: Missing .env value. Ensure you have an .env file within the dir of this sample app.',
    );
    return '';
  }
})();

export const CONFIDENTIAL_CLIENT = Buffer.from(
  `${process.env.REST_OAUTH_CLIENT}:${process.env.REST_OAUTH_SECRET}`,
).toString('base64');

export const PORT = process.env.PORT || 9443;

export const REALM_PATH = process.env.REALM_PATH;

export const SERVER_TYPE = process.env.SERVER_TYPE;

export const REST_OAUTH_CLIENT = process.env.REST_OAUTH_CLIENT;