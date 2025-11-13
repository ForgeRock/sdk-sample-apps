/*
 * ping-sample-web-react-journey
 *
 * journey-client.utils.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { journey } from '@forgerock/journey-client';
import { SERVER_URL, CONFIG, DEBUGGER } from '../../../constants.js';

/**
 * @function createJourneyClient - Utility function for creating a DaVinci client
 * @returns {Object} - Either a Journey client if it has been initialized or null
 */
export default async function createJourneyClient() {
  /** *******************************************************************
   * SDK INTEGRATION POINT
   * Summary: Initialize the Journey client
   * --------------------------------------------------------------------
   * Details: Initialize the Journey client with the same configuration
   * settings used for the OIDC client.
   ******************************************************************* */
  if (DEBUGGER) debugger;

  try {
    // TODO: remove overriding this config when SDK supports wellknown
    const journeyConfig = {
      ...CONFIG,
      serverConfig: {
        baseUrl: SERVER_URL,
      },
    };
    const journeyClient = await journey({ config: journeyConfig });
    return journeyClient;
  } catch (error) {
    console.error('Error creating journey client');
    return null;
  }
}
