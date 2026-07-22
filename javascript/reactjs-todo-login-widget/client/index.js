/*
 * forgerock-sample-web-react
 *
 * index.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { configuration, protect, user } from '@forgerock/login-widget';
import React from 'react';
import ReactDOM from 'react-dom/client';

import Router from './router';
import { DEBUGGER, WEB_OAUTH_CLIENT, SCOPE, WELLKNOWN_URL, PINGONE_ENV_ID } from './constants';
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
 * - journeyClient.serverConfig.wellknown: the OpenID Connect discovery URL used
 *   by the Journey Client to communicate with Ping AM
 * - oidcClient.clientId: the OAuth 2.0 client registered in Ping AM
 * - oidcClient.redirectUri: the URI this app redirects to after OAuth authorization
 * - oidcClient.scope: the OAuth 2.0 scopes requested from Ping AM
 * - oidcClient.serverConfig.wellknown: the OpenID Connect discovery URL used
 *   by the OIDC client for token and userinfo endpoints
 *************************************************************************** */
if (DEBUGGER) debugger;

/**
 * Initialize PingOne Protect as early as possible for data collection.
 * Must run at module scope — not inside a React component — so it fires
 * exactly once at bootstrap rather than on every render cycle.
 */
if (!PINGONE_ENV_ID) {
  console.error('Missing PingOne environment ID for Protect initialization');
} else {
  protect.start({ envId: PINGONE_ENV_ID });
  console.log('PingOne Protect initialized at bootstrap');
}

configuration().set({
  journeyClient: {
    serverConfig: { wellknown: WELLKNOWN_URL },
  },
  oidcClient: {
    clientId: WEB_OAUTH_CLIENT,
    redirectUri: `${window.location.origin}/callback.html`,
    scope: SCOPE,
    serverConfig: { wellknown: WELLKNOWN_URL },
  },
});

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  /** *************************************************************************
   * LOGIN WIDGET INTEGRATION POINT
   * Summary: Get OAuth/OIDC tokens before the first render
   * --------------------------------------------------------------------------
   * Details: We call user.tokens().get() and await it *before* rendering so the
   * app's initial auth state is correct on the very first paint. Doing this here
   * (rather than in a post-mount effect) prevents ProtectedRoute from briefly
   * seeing a "logged out" state on reload and flashing the sign-in page.
   ************************************************************************* */
  if (DEBUGGER) debugger;
  let isAuthenticated = false;
  try {
    const event = await user.tokens().get();
    isAuthenticated = !!event?.response?.accessToken;
  } catch (err) {
    console.error(`Error: token retrieval for hydration; ${err}`);
  }

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
    const auth = useInitAuthState(isAuthenticated);
    const theme = initTheme();

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
