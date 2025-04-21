/*
 * angular-todo-prototype
 *
 * create-client.utils.ts
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { davinci } from '@forgerock/davinci-client';
import createConfig from '../../../utilities/create-config';
import { DaVinciConfig } from '@forgerock/davinci-client/types';
import { DaVinciClient } from './davinci.types';

/**
 * @function createClient - Utility function for creating a DaVinci client
 * @returns {Object} - Either a DaVinci client if it has been initialized or null
 */
export default async function createClient(): Promise<DaVinciClient | null> {
  try {
    const config: DaVinciConfig = createConfig();
    const davinciClient = await davinci({ config });
    return davinciClient;
  } catch (error) {
    console.error('Error creating DaVinci client');
    return null;
  }
}
