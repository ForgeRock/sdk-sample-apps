/*
 * forgerock-sample-web-react
 *
 * index.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { configuration, protect } from '@forgerock/login-widget';
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
import { initTheme, ThemeContext } from './context/theme.context';
import { useInitAuthState, AuthContext } from './context/auth.context';

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
(function initAndHydrate() {
  /**
   * @function Init - Initializes React, State, and Protect
   * @returns {Object} - React component object
   */
  function Init() {
    /**
     * This leverages context with React's Context API.
     * This can be useful to share state with any component without
     * having to pass props through deeply nested components,
     * authentication status and theme state are good examples.
     *
     * If context becomes a more complex function of the app,
     * something like Redux might be a better option.
     */
    const auth = useInitAuthState();
    const theme = initTheme();

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
      <ThemeContext.Provider value={theme}>
        <AuthContext.Provider value={auth}>
          <Router />
        </AuthContext.Provider>
      </ThemeContext.Provider>
    );
  }

  const rootEl = document.getElementById('root');
  const root = ReactDOM.createRoot(rootEl);

  // Mounts the React app to the existing root element
  root.render(<Init />);
})();
