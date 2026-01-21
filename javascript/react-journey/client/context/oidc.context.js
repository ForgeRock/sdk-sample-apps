/*
 * ping-sample-web-react-journey
 *
 * oidc.context.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useState, createContext } from 'react';
import { DEBUGGER } from '../constants';

/**
 * @function useInitOidcState - A custom hook to get initial OIDC state for managing user authentication
 * @param {Object} props - The object representing React's props
 * @param {string} props.email - User's email
 * @param {boolean} props.isAuthenticated - Boolean value of user's auth status
 * @param {string} props.username - User's username
 * @param {Object} props.oidcClient - The OIDC client
 * @returns {Array} - OIDC state values and state methods
 */
export function useInitOidcState({ email, isAuthenticated, username, oidcClient }) {
  /**
   * Create state properties for "global" OIDC state.
   * Using internal names that differ from external to prevent shadowing.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [authenticated, setAuthentication] = useState(isAuthenticated || false);
  const [mail, setEmail] = useState(email || '');
  const [name, setUser] = useState(username || '');

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
