/*
 * ping-sample-web-react-davinci
 *
 * index.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { Config, TokenStorage } from '@forgerock/javascript-sdk';
import React from 'react';
import ReactDOM from 'react-dom/client';
import createConfig from './utilities/create-config';
import Router from './router';
import { DEBUGGER, INIT_PROTECT } from './constants';
import { AppContext, useGlobalStateMgmt } from './global-state';
import { initProtectApi } from './utilities/protect.api';

/**
 * This import will produce a separate CSS file linked in the index.html
 * Webpack will detect this and transpile, process and generate the needed CSS file
 */
import './styles/index.scss';

/** ***************************************************************************
 * SDK INTEGRATION POINT
 * Summary: Configure the SDK
 * ----------------------------------------------------------------------------
 * Details: The config generator below will create the following settings which
 * can be passed to the SDK's Config.setAsync() method to initalize the SDK:
 * - clientId: (OAuth 2.0 only) this is the OAuth 2.0 client you created in PingOne
 * - redirectUri: (OAuth 2.0 only) this is the URI/URL of this app to which the
 *   OAuth 2.0 flow redirects
 * - scope: (OAuth 2.0 only) these are the OAuth scopes that you will request from
 *   PingOne
 * - serverConfig: this includes the wellknown URL of your PingOne environment
 *************************************************************************** */
if (DEBUGGER) debugger;

const config = createConfig();

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  // Configure the javascript sdk
  await Config.setAsync(config);

  /** *************************************************************************
   * SDK INTEGRATION POINT
   * Summary: Get OAuth/OIDC tokens from storage
   * --------------------------------------------------------------------------
   * Details: We can immediately call TokenStorage.get() to check for stored
   * tokens. If we have them, you can cautiously assume the user is
   * authenticated.
   ************************************************************************* */

  let isAuthenticated;
  try {
    isAuthenticated = !!(await TokenStorage.get());
  } catch (err) {
    console.error(`Error: token retrieval for hydration; ${err}`);
  }

  /**
   * If the INIT_PROTECT flag is set to 'bootstrap', initialize PingOne Protect as early as
   * possible in the application for data collection. The PingOne environment ID
   * is required while all other options in the configuration are optional.
   */
  if (INIT_PROTECT === 'bootstrap') {
    const protectApi = initProtectApi({ envId: process.env.PINGONE_ENV_ID });
    const result = await protectApi.start();
    if (result?.error) {
      console.error(`Error initializing Protect: ${result.error}`);
    } else {
      console.log('Protect initialized at bootstrap for data collection');
    }
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
