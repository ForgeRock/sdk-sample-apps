/*
 * forgerock-sample-web-react
 *
 * index.js
 *
 * Copyright (c) 2024 Ping Identity. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Config, TokenStorage } from '@forgerock/javascript-sdk';
import React from 'react';
import ReactDOM from 'react-dom/client';

import Router from './router';
import {
  DEBUGGER,
  JOURNEY_LOGIN,
  WEB_OAUTH_CLIENT,
  CENTRALIZED_LOGIN,
  SCOPE,
  WELLKNOWN_URL,
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
const centralLoginParam = urlParams.get('centralLogin');
const journeyParam = urlParams.get('journey');

/** *************************************************************************** 
 * The SDK offers 2 ways of setting the configuration. In the following lines we can see an example for both.
 * `Config.set` is a synchronous way that works with PingAM and AIC, where the developer provides all the 
 * necessary configuration options for the server.
 * `Config.setAsync` is a more modern aynchronous method that allows the discovery of the server endpoints,
 * by using the `WELL-KNOWN/openid-configuration` endpoint for your server.
 * This way supports PingAM, PingAIC, PingOne Services and PingFed when used with `Centralized Login` aka OIDC.
 * 
 * The legacy way of setting up the SDK configuration can be found here. It is advised that developers use `Config.setAsync`
 * 
  config = Config.set({
    clientId: WEB_OAUTH_CLIENT,
    redirectUri: `${window.location.origin}/${CENTRALIZED_LOGIN === 'true' || centralLoginParam === 'true'
        ? 'login?centralLogin=true'
        : 'callback.html'
      }`,
    scope: SCOPE,
    serverConfig: {
      baseUrl: SERVER_URL,
      timeout: '5000',
    },
    realmPath: REALM_PATH,
    tree: `${journeyParam || JOURNEY_LOGIN}`,
  });
 * *************************************************************************** */

let config;
config = await Config.setAsync({
  clientId: WEB_OAUTH_CLIENT, // e.g. PingOne Services Client GUID
  redirectUri: `${window.location.origin}/${
    CENTRALIZED_LOGIN === 'true' || centralLoginParam === 'true'
      ? 'login?centralLogin=true'
      : 'callback.html'
  }`, // Redirect back to your app, e.g. 'https://localhost:8443/login?centralLogin=true' or the domain your app is served.
  scope: SCOPE, // e.g. 'openid profile email address phone revoke' When using PingOne services `revoke` scope is required
  serverConfig: {
    wellknown: WELLKNOWN_URL,
    timeout: '3000', // Any value between 3000 to 5000 is good, this impacts the redirect time to login. Change that according to your needs.
  },
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
