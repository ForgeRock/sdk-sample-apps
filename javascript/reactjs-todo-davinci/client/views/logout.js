/*
 * ping-sample-web-react-davinci
 *
 * logout.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext, useEffect } from 'react';
import { OidcContext } from '../context/oidc.context.js';
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
  const [, { setAuthentication, setEmail, setUser }] = useContext(OidcContext);

  useEffect(() => {
    async function logout() {
      try {
        /**
         * Logout and clear existing, stored data.
         * Note that setAuthentication(false) triggers the OIDC client logout,
         * revoking tokens and ending the session on PingOne.
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
