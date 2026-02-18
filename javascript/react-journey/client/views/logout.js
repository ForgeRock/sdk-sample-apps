/*
 * ping-sample-web-react-journey
 *
 * logout.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext, useEffect } from 'react';
import Loading from '../components/utilities/loading';
import { OidcContext } from '../context/oidc.context';

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
    /**
     * Logout and clear existing, stored data
     * Note that the setAuthentication method below calls the oidcClient.user.logout
     * method, ensuring the access artifacts are revoked on Ping.
     */
    setAuthentication(false);
    setEmail('');
    setUser('');
  }, []);

  return <Loading classes="pt-5" message="You're being logged out ..." />;
}
