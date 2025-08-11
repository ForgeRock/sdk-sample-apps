/*
 * ping-sample-web-react-davinci
 *
 * protect.utils.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { getProtectApi } from '../../utilities/protect.api.js';

/**
 * @function updateProtectCollector - Update the Protect collector with the data collected
 * @returns {Promise<void>}
 */
export async function updateProtectCollector(protectCollectorUpdater) {
  /**
   * Use the `getData()` method to retrieve the device profiling and behavioral data
   * collected since initialization. Then set the data on the ProtectCollector.
   */
  const protectApi = getProtectApi();
  const data = await protectApi.getData();
  if (typeof data !== 'string' && 'error' in data) {
    console.error(`Failed to retrieve data from PingOne Protect: ${data.error}`);
    return;
  }

  const result = protectCollectorUpdater(data);
  if (result && 'error' in result) {
    console.error(`Error updating ProtectCollector: ${result.error.message}`);
  }
}
