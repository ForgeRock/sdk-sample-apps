/*
 * forgerock-sample-web-react
 *
 * index.js
 *
 * Copyright (c) 2024 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Config, TokenStorage } from '@forgerock/javascript-sdk';
import { PIProtect } from '@forgerock/ping-protect';
import React from 'react';
import ReactDOM from 'react-dom/client';

import Router from './router';
import {
  DEBUGGER,
  JOURNEY_LOGIN,
  WEB_OAUTH_CLIENT,
  SERVER_URL,
  REALM_PATH,
  SCOPE,
  INIT_PROTECT,
  PINGONE_ENV_ID,
} from './constants';
import { AppContext, useGlobalStateMgmt } from './global-state';

/**
 * This import will produce a separate CSS file linked in the index.html
 * Webpack will detect this and transpile, process and generate the needed CSS file
 */
import './styles/index.scss';

/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the SDK
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
 *************************************************************************** */
if (DEBUGGER) debugger;

const urlParams = new URLSearchParams(window.location.search);
const journeyParam = urlParams.get('journey');

/** ***************************************************************************
 * Configure the SDK for embedded login (journey) flow.
 * *************************************************************************** */
Config.set({
  clientId: WEB_OAUTH_CLIENT,
  redirectUri: `${window.location.origin}/callback.html`,
  scope: SCOPE,
  serverConfig: {
    baseUrl: SERVER_URL,
    timeout: '5000',
  },
  realmPath: REALM_PATH,
  tree: `${journeyParam || JOURNEY_LOGIN}`,
});

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  /** *************************************************************************
   * SDK INTEGRATION POINT
   * Summary: Get OAuth/OIDC tokens from storage
   * --------------------------------------------------------------------------
   * Details: We can immediately call TokenStorage.get() to check for stored
   * tokens. If we have them, you can cautiously assume the user is
   * authenticated.
   ************************************************************************* */
  if (DEBUGGER) debugger;
  let isAuthenticated;
  try {
    isAuthenticated = !!(await TokenStorage.get());
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
     * If the INIT_PROTECT flag is set to 'bootstrap', initialize PingOne Protect as early as
     * possible in the application for data collection. The PingOne environment ID
     * is required while all other options in the configuration are optional.
     */
    if (INIT_PROTECT === 'bootstrap') {
      if (!PINGONE_ENV_ID) {
        console.error('Missing PingOne environment ID for Protect initialization');
      } else {
        PIProtect.start({ envId: PINGONE_ENV_ID });
        console.log('PingOne Protect initialized at bootstrap');
      }
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
