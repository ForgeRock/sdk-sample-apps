/*
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, {useEffect, useRef} from 'react';
import type {PropsWithChildren} from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import {
  NativeModules,
} from 'react-native';

import { DEBUGGER_OFF } from '../.env';
import Theme from './theme/index';
import { AppContext, useGlobalStateMgmt } from './global-state';
import Router from './router';

const { FRAuthSampleBridge } = NativeModules;

function App(): React.JSX.Element {
  const stateMgmt = useGlobalStateMgmt({});
    // Track if the bridge has been initialized
  const isInitialized = useRef(false);
   // Start the FRAuthSampleBridge and set the initialization state
   useEffect(() => {
    const initializeFRAuth = async () => {
      try {
        if(!isInitialized.current && FRAuthSampleBridge) {
            await FRAuthSampleBridge.start();
        }
 // Await the asynchronous operation Set the state once initialized
      } catch (error) {
        console.error('Error initializing FRAuthSampleBridge:', error);
      }
    };
    initializeFRAuth();
}, []);

return (
  <Theme>
    <AppContext.Provider value={stateMgmt}>
      <SafeAreaProvider>
        <Router />
      </SafeAreaProvider>
    </AppContext.Provider>
  </Theme>
);
}

export default App;
