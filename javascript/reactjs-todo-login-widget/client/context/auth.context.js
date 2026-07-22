/*
 * forgerock-sample-web-react
 *
 * auth.context.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { user } from '@forgerock/login-widget';
import React, { useState } from 'react';

import { DEBUGGER } from '../constants';

/**
 * @function useInitAuthState - Custom hook for managing user authentication and page
 * @param {boolean|null} isAuthenticated - Auth status resolved before render. The default is `null` ("not yet known") rather than `false` so that if this
 * value is ever unavailable at call time, ProtectedRoute waits (shows Loading)
 * @returns {Array} - Auth state values and state methods
 */
export function useInitAuthState(isAuthenticated = null) {
  /**
   * Create state properties for auth state.
   * The destructing of the hook's array results in index 0 having the state value,
   * and index 1 having the "setter" method to set new state values.
   */
  const [authenticated, setAuthentication] = useState(isAuthenticated);
  const [mail, setEmail] = useState(() => window.sessionStorage.getItem('sdk_email') || '');
  const [name, setUser] = useState(() => window.sessionStorage.getItem('sdk_username') || '');
  const [error, setError] = useState('');

  /**
   * @function setAuthenticationWrapper - A wrapper for storing authentication in sessionStorage
   * @param {boolean} value - current user authentication
   * @returns {void}
   */
  async function setAuthenticationWrapper(value) {
    if (value === false) {
      /** *********************************************************************
       * LOGIN WIDGET INTEGRATION POINT
       * Summary: Logout, end session and revoke tokens
       * ----------------------------------------------------------------------
       * Details: Since this method is available via the Context API,
       * any part of the application can log a user out. This is helpful when
       * APIs are called and we get a 401 response.
       ********************************************************************* */
      if (DEBUGGER) debugger;
      try {
        await user.logout();
        location.assign(`${document.location.origin}/`);
      } catch (err) {
        console.error(`Error: logout did not successfully complete; ${err}`);
      }
    }

    if (value === true) {
      setError('');
    }
    setAuthentication(value);
  }

  /**
   * @function setErrorWrapper - A wrapper for setting auth-related errors
   * @param {string} value - error message
   * @returns {void}
   */
  function setErrorWrapper(value) {
    setError(value || '');
  }

  /**
   * @function setEmailWrapper - A wrapper for storing authentication in sessionStorage
   * @param {string} value - current user's email
   * @returns {void}
   */
  function setEmailWrapper(value) {
    window.sessionStorage.setItem('sdk_email', `${value}`);
    setEmail(value);
  }

  /**
   * @function setUserWrapper - A wrapper for storing authentication in sessionStorage
   * @param {string} value - current user's username
   * @returns {void}
   */
  function setUserWrapper(value) {
    window.sessionStorage.setItem('sdk_username', `${value}`);
    setUser(value);
  }

  /**
   * returns an array with state object as index zero and setters as index one
   */
  return [
    {
      isAuthenticated: authenticated,
      email: mail,
      username: name,
      error,
    },
    {
      setAuthentication: setAuthenticationWrapper,
      setEmail: setEmailWrapper,
      setUser: setUserWrapper,
      setError: setErrorWrapper,
    },
  ];
}

/**
 * @constant AuthContext - Creates React Context API
 * This provides the capability to set auth state in React
 * without having to pass the state as props through parent-child components.
 */
export const AuthContext = React.createContext([{}, {}]);
