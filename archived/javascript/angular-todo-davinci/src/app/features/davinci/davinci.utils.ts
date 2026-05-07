/*
 * ping-sample-web-angular-davinci
 *
 * davinci.utils.ts
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { davinci } from '@forgerock/davinci-client';
import createConfig from '../../../utilities/create-config';
import { DaVinciConfig, DavinciClient } from '@forgerock/davinci-client/types';

/**
 * @function createClient - Utility function for creating a DaVinci client
 * @returns {Object} - Either a DaVinci client if it has been initialized or null
 */
export default async function createClient(): Promise<DavinciClient | null> {
  try {
    const config: DaVinciConfig = createConfig();
    const davinciClient = await davinci({ config });
    return davinciClient;
  } catch (error) {
    console.error('Error creating DaVinci client');
    return null;
  }
}
