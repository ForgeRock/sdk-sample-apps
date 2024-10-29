/*
 * ping-sample-web-react-davinci
 *
 * create-client.utils.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { davinci } from '@forgerock/davinci-client';
import createConfig from '../../../utilities/create-config.js';

/**
 * @function createClient - Custom React hook that returns the DaVinci client
 * @returns {Object} - Either a DaVinci client if it has been initialized or null
 */
export default async function createClient() {
  try {
    const config = createConfig();
    const davinciClient = await davinci({ config });
    return davinciClient;
  } catch (error) {
    console.error('Error creating DaVinci client');
    return null;
  }
}
