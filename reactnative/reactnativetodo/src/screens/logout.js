/*
 * forgerock-react-native-sample
 *
 * logout.js
 *
 * Copyright (c) 2021 ForgeRock. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext, useEffect } from 'react';
import { NativeModules } from 'react-native';

/*
 * Please ensure you have created an .env.js from the
 * .env.example.js template!
 */
import { DEBUGGER_OFF } from '../../.env';
import { AppContext } from '../global-state';
import Loading from '../components/utilities/loading';

const { FRAuthSampleBridge } = NativeModules;

export default function Logout() {
  const [_, { setAuthentication }] = useContext(AppContext);

  /**
   * Since calling logout is asynchronous, we're wrapping the call
   * in a `useEffect` and updating the state upon completion.
   */
  useEffect(() => {
    async function logout() {
      try {
        /** *********************************************************************
         * NATIVE BRIDGE SDK INTEGRATION POINT
         * Summary: Call Logout
         * ----------------------------------------------------------------------
         * Details: We can utilize the logout method to completely
         * revoke existing access artifacts on ForgeRock
         * ******************************************************************** */
        if (!DEBUGGER_OFF) debugger;
        await FRAuthSampleBridge.logout();
      } catch (err) {
        console.error(`Error: logout; ${err}`);
      }
      setAuthentication(false);
    }
    logout();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return <Loading message="You're being logged out ..." />;
}
