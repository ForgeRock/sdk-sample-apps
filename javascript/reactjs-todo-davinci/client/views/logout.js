/*
 * ping-sample-web-react-davinci
 *
 * logout.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext, useEffect } from 'react';
import { AppContext } from '../global-state';
import Loading from '../components/utilities/loading';

/**
 * @function Logout - React view for Logout
 * @returns {Object} - React component object
 */
export default function Logout() {
  /**
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [, { setAuthentication, setEmail, setUser }] = useContext(AppContext);

  useEffect(() => {
    async function logout() {
      try {
        /**
         * Logout and clear existing, stored data
         * Note that the setAuthentication method below calls the FRUser.logout
         * method, ensuring the access artifacts are revoked on PingOne.
         */
        setAuthentication(false);
        setEmail('');
        setUser('');
      } catch (error) {
        console.error(`Error: logout; ${error}`);
      }
    }

    logout();

    // All methods/functions used herein are are "stable"
  }, []);

  return <Loading classes="pt-5" message="You're being logged out ..." />;
}
