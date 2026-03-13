/*
 * ping-sample-web-react-todo-oidc
 *
 * oidc.context.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { useEffect, useState, createContext } from 'react';
import { oidc } from '@forgerock/oidc-client';
import { CONFIG, DEBUGGER } from '../constants';

const email = window.sessionStorage.getItem('sdk_email');
const username = window.sessionStorage.getItem('sdk_username');

/**
 * @function useInitOidcState - Initialize global OIDC state
 * @returns {Array} - OIDC state and state mutator methods
 */
export function useInitOidcState() {
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
       * We initialize it at bootstrap to check for stored tokens. If we have them,
       * we can cautiously assume the user is authenticated. The OIDC client will
       * later be stored in React Context and used throughout the app.
       * Note: We chose to initialize the OIDC client here for readability,
       * but it can be done outside of the React component for better performance.
       ************************************************************************* */
      if (DEBUGGER) debugger;
      let client = await oidc({ config: CONFIG });
      if ('error' in client) {
        console.error(`Error initializing OIDC client: ${client.error}`);
        client = null;
      } else {
        const tokens = await client.token.get();
        setAuthentication(!tokens.error);
      }
      setOidcClient(client);
    }

    if (!oidcClient) {
      initOidcClient();
    }
  }, [oidcClient]);

  /**
   * @function setAuthenticationWrapper - Wrapper for authentication state updates
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
   * @function setEmailWrapper - Wrapper for email state updates
   * @param {string} value - Current user's email
   * @returns {void}
   */
  function setEmailWrapper(value) {
    window.sessionStorage.setItem('sdk_email', `${value}`);
    setEmail(value);
  }

  /**
   * @function setUserWrapper - Wrapper for username state updates
   * @param {string} value - Current user's username
   * @returns {void}
   */
  function setUserWrapper(value) {
    window.sessionStorage.setItem('sdk_username', `${value}`);
    setUser(value);
  }

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
 * @constant OidcContext - Creates React Context to store OIDC state
 */
export const OidcContext = createContext([{}, {}]);
