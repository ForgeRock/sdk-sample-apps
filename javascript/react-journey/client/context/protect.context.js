/*
 * ping-sample-web-react-journey
 *
 * protect.context.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { createContext, useState, useEffect } from 'react';
import { protect } from '@forgerock/protect';
import { DEBUGGER, INIT_PROTECT } from '../constants';

const urlParams = new URLSearchParams(window.location.search);
const protectInitMode = INIT_PROTECT || urlParams.get('initProtect');

/**
 * @function useInitProtectApi - A custom hook to get a bootstrapped Protect API
 * @returns {Array} - A Protect API if opting for bootstrap initialization and a setter method
 */
export function useInitProtect(config) {
  /**
   * Create state properties for "global" Protect API.
   * The destructing of the hook's array results in index 0 having the Protect API,
   * and index 1 having the "setter" method to set a new API.
   */
  const [protectApi, setProtectApi] = useState(null);

  useEffect(() => {
    async function bootstrapProtect() {
      /** *************************************************************************
       * SDK INTEGRATION POINT
       * Summary: Initialize Protect at bootstrap
       * --------------------------------------------------------------------------
       * Details: If the INIT_PROTECT flag is set to 'bootstrap', then initialize
       * PingOne Protect as early as possible in the application for data collection.
       * Call the useInitProtect hook as early as possible in your application.
       * The PingOne environment ID is required while all other options in the
       * configuration are optional.
       * Note: We chose to initialize the Protect API here for readability,
       * but it can be done outside of the React component for better performance.
       ************************************************************************* */
      if (DEBUGGER) debugger;
      const api = protect(config);
      const result = await api.start();
      if (result?.error) {
        console.error(`Error initializing Protect: ${result.error}`);
      } else {
        console.log('Protect initialized at bootstrap for data collection');
      }
      setProtectApi(api);
    }

    if (protectInitMode === 'bootstrap' && !protectApi) {
      bootstrapProtect();
    }
  }, [protectApi]);

  /**
   * Returns an array with Protect API or null at index zero and setter at index one
   */
  return [protectApi, setProtectApi];
}

/**
 * @constant ProtectContext - Creates React Context to store Protect API
 * This provides the capability to set a global Protect API state in React
 * without having to pass the state as props through parent-child components.
 */
export const ProtectContext = createContext(null);
