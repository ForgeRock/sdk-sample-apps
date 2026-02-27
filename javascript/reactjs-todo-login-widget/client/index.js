/*
 * forgerock-sample-web-react
 *
 * index.js
 *
 * Copyright (c) 2024 - 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { configuration, protect, user } from '@forgerock/login-widget';
import React from 'react';
import ReactDOM from 'react-dom/client';

import Router from './router';
import {
  DEBUGGER,
  JOURNEY_LOGIN,
  WEB_OAUTH_CLIENT,
  SCOPE,
  SERVER_URL,
  REALM_PATH,
  PINGONE_ENV_ID,
} from './constants';
import { AppContext, useGlobalStateMgmt } from './global-state';

/**
 * This import will produce a separate CSS file linked in the index.html
 * Webpack will detect this and transpile, process and generate the needed CSS file
 */
import './styles/index.scss';

/** ***************************************************************************
 * LOGIN WIDGET INTEGRATION POINT
 * Summary: Configure the Login Widget
 * ----------------------------------------------------------------------------
 * Details: Below, you will see the following settings:
 * - clientId: (OAuth 2.0 only) this is the OAuth 2.0 client you created in Ping, such as `ForgeRockSDKClient`
 * - redirectUri: (OAuth 2.0 only) this is the URI/URL of this app to which the
 *   OAuth 2.0 flow redirects
 * - scope: (OAuth 2.0 only) these are the OAuth scopes that you will request from
 *   Ping
 * - serverConfig: this includes the baseUrl of your Ping AM, and should
 *   include the deployment path at the end, such as `/am/` or `/openam/`
 * - realmPath: this is the realm to use within Ping. such as `alpha` or `root`
 * - tree: The authentication journey/tree to use, such as `sdkAuthenticationTree`
 * - tokenStore: The API to use for storing tokens on the client, such as `localStorage` or `sessionStorage`
 *************************************************************************** */
if (DEBUGGER) debugger;

const urlParams = new URLSearchParams(window.location.search);
const journeyParam = urlParams.get('journey');

configuration().set({
  forgerock: {
    // Minimum required configuration:
    serverConfig: {
      baseUrl: SERVER_URL,
      timeout: 3000,
    },
    // Optional configuration:
    clientId: WEB_OAUTH_CLIENT,
    realmPath: REALM_PATH,
    redirectUri: `${window.location.origin}/callback.html`,
    scope: SCOPE,
    tree: `${journeyParam || JOURNEY_LOGIN}`,
    tokenStore: 'localStorage',
  },
});

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  /** *************************************************************************
   * LOGIN WIDGET INTEGRATION POINT
   * Summary: Get OAuth/OIDC tokens
   * --------------------------------------------------------------------------
   * Details: We can immediately call user.tokens().get() to check for stored
   * tokens. If we have them, you can cautiously assume the user is
   * authenticated.
   ************************************************************************* */
  if (DEBUGGER) debugger;
  let isAuthenticated;
  try {
    const event = await user.tokens().get();
    isAuthenticated = !!event?.response?.accessToken;
  } catch (err) {
    console.error(`Error: token retrieval for hydration; ${err}`);
  }

  /**
   * Pull custom values from outside of the app to (re)hydrate state.
   */
  const prefersDarkTheme = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const email = window.sessionStorage.getItem('sdk_email');
  const username = window.sessionStorage.getItem('sdk_username');
  const rootEl = document.getElementById('root');

  if (prefersDarkTheme) {
    document.body.classList.add('cstm_bg-dark', 'bg-dark');
  }

  /**
   * @function Init - Initializes React and global state
   * @returns {Object} - React component object
   */
  function Init() {
    /**
     * This leverages "global state" with React's Context API.
     * This can be useful to share state with any component without
     * having to pass props through deeply nested components,
     * authentication status and theme state are good examples.
     *
     * If global state becomes a more complex function of the app,
     * something like Redux might be a better option.
     */
    const stateMgmt = useGlobalStateMgmt({
      email,
      isAuthenticated,
      prefersDarkTheme,
      username,
    });

    /**
     * Initialize PingOne Protect as early as possible in the application for data collection.
     * The PingOne environment ID is required while all other options in the configuration are optional.
     */
    if (!PINGONE_ENV_ID) {
      console.error('Missing PingOne environment ID for Protect initialization');
    } else {
      protect.start({ envId: PINGONE_ENV_ID });
      console.log('PingOne Protect initialized at bootstrap');
    }

    return (
      <AppContext.Provider value={stateMgmt}>
        <Router />
      </AppContext.Provider>
    );
  }

  const root = ReactDOM.createRoot(rootEl);
  // Mounts the React app to the existing root element
  root.render(<Init />);
})();
