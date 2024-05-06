/*
 * forgerock-sample-web-react
 *
 * ping-protect.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { PIProtect } from '@forgerock/ping-protect';
import React, { useEffect } from 'react';
import Loading from '../utilities/loading';

/**
 * @function PingProtect - React component used for interacting with the Ping Protect callbacks
 * @param {Object} props - React props object passed from parent
 * @returns {Object} - React component object
 */
export default function PingProtect({ callback, submit }) {
  const isInitialize = callback.getType() === 'PingOneProtectInitializeCallback';

  useEffect(() => {
    async function startProtect() {
      const config = callback.getConfig();
      try {
        debugger;
        await PIProtect.start(config);
      } catch (e) {
        callback.setClientError(e.message);
      }
      submit();
    }

    async function collectProtect() {
      try {
        const data = await PIProtect.getData();
        debugger;
        callback.setData(data);
      } catch (e) {
        callback.setClientError(e.message);
      }
      submit();
    }

    if (isInitialize) {
      startProtect();
    } else {
      collectProtect();
    }
  }, []);

  return <Loading message={`${isInitialize ? 'Initializing' : 'Collecting'} profiling ... `} />;
}
