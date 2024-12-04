/*
 * forgerock-sample-web-react
 *
 * constants.mjs
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Buffer } from 'buffer';
import * as constants from '../.env.js';

export const AM_URL = (() => {
  try {
    const lastChar = constants.AM_URL.slice(-1);
    if (lastChar !== '/') {
      return constants.AM_URL + '/';
    }
    return constants.AM_URL;
  } catch (err) {
    console.error(
      'ERROR: Missing .env.js value. Ensure you have an .env.js file within the dir of this sample app.',
    );
    return '';
  }
})();

export const CONFIDENTIAL_CLIENT = Buffer.from(
  `${constants.REST_OAUTH_CLIENT}:${constants.REST_OAUTH_SECRET}`,
).toString('base64');

export const PORT = constants.API_PORT || 9443;

export const REALM_PATH = constants.REALM_PATH;
