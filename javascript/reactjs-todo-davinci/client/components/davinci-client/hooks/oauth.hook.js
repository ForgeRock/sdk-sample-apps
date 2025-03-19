/*
 * ping-sample-web-react-davinci
 *
 * oauth.hook.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useState } from 'react';
import { TokenManager, UserManager } from '@forgerock/javascript-sdk';
import { DEBUGGER } from '../../../constants.js';

/**
 * @function useOAuth - Custom React hook that manages authorization
 * @returns {Object} - An array containing user state and a method to set the authorizaton code
 */
export default function useOAuth() {
  const [user, setUser] = useState(null);
  const [authCode, setAuthCode] = useState(null);
  const [authState, setAuthState] = useState(null);

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
       * Summary: Get OAuth/OIDC tokens with Authorization Code Flow w/PKCE.
       * ----------------------------------------------------------------------
       * Details: Since we have successfully authenticated the user, we can now
       * get the OAuth2/OIDC tokens. We are passing the `forceRenew` option to
       * ensure we get fresh tokens, regardless of existing tokens.
       ************************************************************************* */
      if (DEBUGGER) debugger;
      try {
        await TokenManager.getTokens({
          query: { code: authCode, state: authState },
          forceRenew: true,
        });
      } catch (err) {
        console.error(`Error: get tokens; ${err}`);
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
      try {
        const user = await UserManager.getCurrentUser();
        setUser(user);
      } catch (err) {
        console.error(`Error: get current user; ${err}`);
        setUser(null);
      }
    }

    if (authCode && authState) {
      getOAuth();
    }
  }, [authCode, authState]);

  return [user, setCode];
}
