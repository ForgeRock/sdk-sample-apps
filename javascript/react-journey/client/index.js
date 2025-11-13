/*
 * ping-sample-web-react-journey
 *
 * index.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { PIProtect } from '@forgerock/ping-protect';
import React from 'react';
import ReactDOM from 'react-dom/client';
import Router from './router';
import { CONFIG, DEBUGGER, INIT_PROTECT, PINGONE_ENV_ID } from './constants';
import { AppContext, useGlobalStateMgmt } from './global-state';
import { oidc } from '@forgerock/oidc-client';
import { OidcProvider } from './oidc-client';
import Loading from './components/utilities/loading';

/**
 * This import will produce a separate CSS file linked in the index.html
 * Webpack will detect this and transpile, process and generate the needed CSS file
 */
import './styles/index.scss';

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  let isAuthenticated;
  let oidcClient;

  try {
    /** *************************************************************************
     * SDK INTEGRATION POINT
     * Summary: Initialize OIDC client and get OAuth/OIDC tokens from storage
     * --------------------------------------------------------------------------
     * Details: The OIDC client is used to manage authorization, tokens, and users.
     * We intitialize it at bootstrap to check for stored tokens. If we have them,
     * we can cautiously assume the user is authenticated. The OIDC client will
     * later be stored in React Context and used throughout the app.
     ************************************************************************* */
    if (DEBUGGER) debugger;
    oidcClient = await oidc({ config: CONFIG });
    const tokens = await oidcClient.token.get();
    isAuthenticated = !tokens.error;
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
    if (!oidcClient) {
      return <Loading message="Initializing application..." />;
    }

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
      oidcClient,
    });

    /**
     * If the INIT_PROTECT flag is set, initialize PingOne Protect as early as
     * possible in the application for data collection. The PingOne environment ID
     * is required while all other options in the configuration are optional.
     */
    if (INIT_PROTECT) {
      if (!PINGONE_ENV_ID) {
        console.error('Missing PingOne environment ID for Protect initialization');
      } else {
        PIProtect.start({ envId: PINGONE_ENV_ID });
        console.log('PingOne Protect initialized at bootstrap');
      }
    }

    return (
      /**
       * Pass the OIDC client to the OidcProvider to store it in React Context
       * for use throughout the app.
       */
      <OidcProvider client={oidcClient}>
        <AppContext.Provider value={stateMgmt}>
          <Router />
        </AppContext.Provider>
      </OidcProvider>
    );
  }

  const root = ReactDOM.createRoot(rootEl);

  // Mounts the React app to the existing root element
  root.render(<Init />);
})();
