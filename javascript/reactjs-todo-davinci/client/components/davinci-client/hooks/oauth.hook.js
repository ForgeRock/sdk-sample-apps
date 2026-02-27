/*
 * ping-sample-web-react-davinci
 *
 * oauth.hook.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useState, useContext } from 'react';
import { OidcContext } from '../../../context/oidc.context.js';
import { DEBUGGER } from '../../../constants.js';

/**
 * @function useOAuth - Custom React hook that manages authorization
 * @returns {Object} - An array containing user state and a method to set the authorizaton code
 */
export default function useOAuth() {
  const [user, setUser] = useState(null);
  const [authCode, setAuthCode] = useState(null);
  const [authState, setAuthState] = useState(null);
  const [{ oidcClient }] = useContext(OidcContext);

  /**
   * @function setCode - A function that sets the hook's local authorization state
   * @returns {void}
   */
  function setCode({ code, state }) {
    if (code && state) {
      setAuthCode(code);
      setAuthState(state);
    } else {
      console.error('Missing authorization code or state');
    }
  }

  useEffect(() => {
    /**
     * @function getOAuth - The function to call when we get a successful login
     * @returns {Promise<void>}
     */
    async function getOAuth() {
      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Exchange authorization code for OAuth/OIDC tokens.
       * ----------------------------------------------------------------------
       * Details: After a successful login, we receive an authorization
       * code and state. We pass both to `oidcClient.token.exchange()` to
       * complete the Authorization Code Flow w/PKCE and store the resulting
       * tokens via the OIDC client.
       ************************************************************************* */
      if (DEBUGGER) debugger;
      const tokens = await oidcClient.token.exchange(authCode, authState);
      if ('error' in tokens) {
        console.error(`Error: get tokens; ${tokens.error}`);
        return;
      }

      /** *********************************************************************
       * SDK INTEGRATION POINT
       * Summary: Call the user info endpoint for some basic user data.
       * ----------------------------------------------------------------------
       * Details: This is an OAuth2 call that returns user information with a
       * valid access token. This is optional and only used for displaying
       * user info in the UI.
       ********************************************************************* */
      if (DEBUGGER) debugger;
      const user = await oidcClient.user.info();
      if ('error' in user) {
        console.error(`Error: get current user; ${user.error}`);
        setUser(null);
      } else {
        setUser(user);
      }
    }

    if (authCode && authState) {
      getOAuth();
    }
  }, [authCode, authState]);

  return [user, setCode];
}
