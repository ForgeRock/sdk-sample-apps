/*
 * ping-sample-web-react-davinci
 *
 * protect.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState } from 'react';
import { protect } from '@pingidentity/protect';
import { INIT_PROTECT, PINGONE_ENV_ID } from '../../constants.js';
import { AppContext } from '../../global-state.js';
import Loading from '../utilities/loading.js';

export default function Protect({ collector, updater, submit }) {
  const [loading, setLoading] = useState(true);
  const [loadingMessage, setLoadingMessage] = useState('');
  // eslint-disable-next-line no-unused-vars
  const [state, { setProtectAPI }] = useContext(AppContext);

  useEffect(() => {
    async function handleProtectTextCollector() {
      /**
       * A TextCollector with name protectsdk is sent with the first node of the flow,
       * but it is not needed. It is a self-submitting node which requires no
       * user interaction. While you would normally load the Protect module
       * here and wait for a response, we instead mock the response with a
       * dummy value and update the collector. Then call the
       * submit function to proceed with the flow.
       */
      updater('fakeprofile');
      setLoading(false);
      if (submit !== undefined) {
        await submit();
      }
    }

    async function handleProtectCollector() {
      try {
        if (!INIT_PROTECT && !state.protectAPI) {
          /**
           * If the INIT_PROTECT flag is false, rely on the configuration from the PingOne
           * Protect Collector's output to initialize the Protect API. Then call the API's
           * start method to begin collecting data.
           */
          setLoadingMessage('Initializing PingOne Protect...');

          const config = collector.output.config;
          const protectAPI = await protect({
            envId: PINGONE_ENV_ID,
            behavioralDataCollection: config.behavioralDataCollection,
            // universalDeviceIdentification: config.universalDeviceIdentification, // This feature is not yet supported
          });

          setProtectAPI(protectAPI);
          await protectAPI.start();
          console.log('PingOne Protect initialized by collector. Collecting data...');
        }
      } catch (err) {
        console.error(`Failed to initialize PingOne Protect for data collection`, err);
      } finally {
        setLoadingMessage('');
        setLoading(false);
      }
    }

    if (collector.type === 'TextCollector' && collector.name === 'protectsdk') {
      handleProtectTextCollector();
    } else if (collector.type === 'ProtectCollector') {
      handleProtectCollector();
    }
  }, [updater, submit, collector, state.protectAPI]);

  return loading ? <Loading key="loading-protect" message={loadingMessage} /> : null;
}
