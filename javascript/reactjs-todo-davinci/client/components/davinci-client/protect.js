/*
 * ping-sample-web-react-davinci
 *
 * protect.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useEffect, useState } from 'react';
import Loading from '../utilities/loading.js';
import { initProtectApi } from '../../utilities/protect.api.js';
import { INIT_PROTECT, PINGONE_ENV_ID } from '../../constants.js';

export default function Protect({ collector }) {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function initProtect() {
      try {
        /**
         * If the INIT_PROTECT flag is false, rely on the configuration from the PingOne
         * Protect Collector's output to initialize the Protect API. Then call the API's
         * start method to begin collecting data.
         */
        if (!INIT_PROTECT) {
          const config = collector.output.config;
          const protectApi = initProtectApi({
            envId: PINGONE_ENV_ID,
            behavioralDataCollection: config.behavioralDataCollection,
            // universalDeviceIdentification: config.universalDeviceIdentification, // This feature is not yet supported
          });

          const error = await protectApi.start();
          if (!error) {
            console.log('PingOne Protect initialized by collector for data collection');
          } else {
            console.error(`Error initializing Protect: ${error.error}`);
          }
        }
      } catch (err) {
        console.error(`Failed to initialize PingOne Protect`, err);
      } finally {
        setLoading(false);
      }
    }

    initProtect();
  }, [collector]);

  return loading ? (
    <Loading key="loading-protect" message="Initializing PingOne Protect..." />
  ) : null;
}
