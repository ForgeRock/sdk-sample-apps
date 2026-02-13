/*
 * ping-sample-web-react-davinci
 *
 * route.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useContext, useEffect, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { DEBUGGER } from '../constants';
import Loading from '../components/utilities/loading';
import { OidcContext } from '../context/oidc.context.js';

/**
 * @function useAuthValidation - Custom hook for validating user authentication
 * @param {boolean} auth - client state on whether user is authenticated
 * @param {function} setAuth - OidcContext setter for updating authentication status
 * @returns {Array}
 */
function useAuthValidation(auth, setAuth) {
  /**
   * React state "hook"
   *
   * This has three possible states: 'unknown', 'valid' and 'invalid'.
   */
  const [isValid, setValid] = useState('unknown');
  const [{ oidcClient }] = useContext(OidcContext);

  useEffect(() => {
    async function validateAccessToken() {
      /**
       * First, check to see if the user has recently been authenticated
       */
      if (auth) {
        /**
         * If we they have been authenticated, validate that assumption
         */
        /** *****************************************************************
         * SDK INTEGRATION POINT
         * Summary: Optional client-side route access validation
         * ------------------------------------------------------------------
         * Details: We call the userinfo endpoint via `oidcClient.user.info()`
         * to confirm the user's access token is still valid before granting
         * route access. If the call fails or returns an error, the user is
         * considered unauthenticated and redirected to login.
         ***************************************************************** */
        if (DEBUGGER) debugger;
        const user = await oidcClient.user.info();
        if ('error' in user) {
          setAuth(false);
          setValid('invalid');
          console.info(`Info: route validation; ${user.error}`);
        } else {
          setValid('valid');
        }
      } else {
        /**
         * If we have no record of their authenticated, no need to call the server
         */
        setValid('invalid');
      }
    }

    validateAccessToken();
    // Only `auth` is mutable, all others, even `setAuth` are "stable"
  }, [auth]);

  return [
    {
      isValid,
    },
  ];
}

/**
 * @function ProtectedRoute - This function extends the ReactRouter component to
 * protect routes from unauthenticated access.
 * Inspired by: https://ui.dev/react-router-v5-protected-routes-authentication/
 * @param {Object} props - React props
 * @param {Object} props.children - React components passed as children
 * @param string[] path - React-Router path prop
 * @returns {Object} - Wrapped React Router component
 */
export function ProtectedRoute({ children }) {
  const [{ isAuthenticated }, { setAuthentication }] = useContext(OidcContext);
  const [{ isValid }] = useAuthValidation(isAuthenticated, setAuthentication);

  switch (isValid) {
    case 'valid':
      // Access token has been confirmed to be valid
      return children;
    case 'invalid':
      // Access token has been confirmed to be invalid
      return <Navigate to="/login" />;
    default:
      // State is 'unknown', so we are waiting on token validation
      return <Loading classes="pt-5" message="Verifying access ... " />;
  }
}
