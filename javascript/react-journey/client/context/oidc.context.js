/*
 * ping-sample-web-react-journey
 *
 * oidc.context.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useState, createContext, useEffect } from 'react';
import { oidc } from '@forgerock/oidc-client';
import { DEBUGGER } from '../constants';

const email = window.sessionStorage.getItem('sdk_email');
const username = window.sessionStorage.getItem('sdk_username');

/**
 * @function useInitOidcState - A custom hook to get initial OIDC state for managing user authentication
 * @returns {Array} - OIDC client, state values and state methods
 */
export function useInitOidcState(config) {
  /**
   * Create state properties for "global" OIDC state.
   * The destructing of the hook's array results in index 0 having the state values,
   * and index 1 having the "setter" methods to set new state values.
   */
  const [oidcClient, setOidcClient] = useState(null);
  const [authenticated, setAuthentication] = useState(false);
  const [mail, setEmail] = useState(email || '');
  const [name, setUser] = useState(username || '');

  useEffect(() => {
    async function initOidcClient() {
      /** *************************************************************************
       * SDK INTEGRATION POINT
       * Summary: Initialize OIDC client and get OAuth/OIDC tokens from storage
       * --------------------------------------------------------------------------
       * Details: The OIDC client is used to manage authorization, tokens, and users.
       * We intitialize it at bootstrap to check for stored tokens. If we have them,
       * we can cautiously assume the user is authenticated. The OIDC client will
       * later be stored in React Context and used throughout the app.
       * Note: We chose to initialize the OIDC client here for readability,
       * but it can be done outside of the React component for better performance.
       ************************************************************************* */
      if (DEBUGGER) debugger;
      let client = await oidc({ config });
      if ('error' in client) {
        console.error(`Error initializing OIDC client: ${client.error}`);
        client = null;
      } else {
        const tokens = await client.token.get();
        const isAuthenticated = !tokens.error;
        setAuthentication(isAuthenticated);
      }
      setOidcClient(client);
    }

    if (!oidcClient) {
      initOidcClient();
    }
  }, [oidcClient]);

  /**
   * @function setAuthenticationWrapper - A wrapper for storing authentication state
   * @param {boolean} value - Current user authentication
   * @returns {void}
   */
  async function setAuthenticationWrapper(value) {
    if (value === false) {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Log user out
       * ----------------------------------------------------------------------
       * Details: Since this method is a global method via the Context API,
       * any part of the application can log a user out. This is helpful when
       * APIs are called and we get a 401 response. The logout method ends the
       * user's session and revokes tokens.
       ********************************************************************* */
      if (DEBUGGER) debugger;
      const response = await oidcClient.user.logout();
      if ('error' in response) {
        console.error('Logout Error:', response);
      } else {
        location.assign(`${window.location.origin}`);
      }
    }
    setAuthentication(value);
  }

  /**
   * @function setEmailWrapper - A wrapper for storing email in sessionStorage
   * @param {string} value - Current user's email
   * @returns {void}
   */
  function setEmailWrapper(value) {
    window.sessionStorage.setItem('sdk_email', `${value}`);
    setEmail(value);
  }

  /**
   * @function setUserWrapper - A wrapper for storing username in sessionStorage
   * @param {string} value - Current user's username
   * @returns {void}
   */
  function setUserWrapper(value) {
    window.sessionStorage.setItem('sdk_username', `${value}`);
    setUser(value);
  }

  /**
   * Returns an array with state object as index zero and setters as index one
   */
  return [
    {
      isAuthenticated: authenticated,
      email: mail,
      username: name,
      oidcClient,
    },
    {
      setAuthentication: setAuthenticationWrapper,
      setEmail: setEmailWrapper,
      setUser: setUserWrapper,
    },
  ];
}

/**
 * @constant OidcContext - Creates React Context to store OIDC client
 * This provides the capability to set a global OIDC client state in React
 * without having to pass the state as props through parent-child components.
 */
export const OidcContext = createContext([{}, {}]);
