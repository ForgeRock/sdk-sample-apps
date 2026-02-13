/*
 * ping-sample-web-react-davinci
 *
 * protect.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useContext, useEffect, useState } from 'react';
import Loading from '../utilities/loading.js';
import { protect } from '@forgerock/protect';
import { ProtectContext } from '../../context/protect.context.js';
import { INIT_PROTECT, PINGONE_ENV_ID } from '../../constants.js';

const urlParams = new URLSearchParams(window.location.search);
const protectInitMode = INIT_PROTECT || urlParams.get('initProtect');

/**
 * @function Protect - React component for initializing DaVinci ProtectCollector
 * @param {Object} collector - DaVinci ProtectCollector containing flow-provided Protect configuration
 * @returns {Object|null} Loading component while initializing Protect in flow mode, otherwise null
 */
export default function Protect({ collector }) {
  const [loading, setLoading] = useState(true);
  const [, setProtectApi] = useContext(ProtectContext);

  useEffect(() => {
    async function handleProtect() {
      /**
       * If the INIT_PROTECT flag is set to 'flow', rely on the configuration from the PingOne
       * ProtectCollector's output to initialize the Protect API. Then call the API's
       * start method to begin collecting data.
       */
      if (protectInitMode === 'flow') {
        const collectorConfig = collector.output.config;
        const protectApiConfig = {
          envId: PINGONE_ENV_ID,
          behavioralDataCollection: collectorConfig.behavioralDataCollection,
          universalDeviceIdentification: collectorConfig.universalDeviceIdentification,
        };

        const api = protect(protectApiConfig);
        setProtectApi(api);

        const result = await api.start();

        if (result?.error) {
          console.error('Failed to initialize PingOne Protect');
        } else {
          console.log('PingOne Protect initialized by collector for data collection');
        }
      }

      setLoading(false);
    }

    handleProtect();
  }, [collector, setProtectApi]);

  return loading ? (
    <Loading key="loading-protect" message="Initializing PingOne Protect..." />
  ) : null;
}
