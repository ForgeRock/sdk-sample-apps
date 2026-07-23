/*
 * forgerock-sample-web-react
 *
 * index.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { configure, protect, user } from '@forgerock/login-widget';
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

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  /** *************************************************************************
   * LOGIN WIDGET INTEGRATION POINT
   * Summary: Configure the Login Widget, then get tokens before first render
   * --------------------------------------------------------------------------
   * Settings:
   * - wellknown: the OpenID Connect discovery URL, supplied once at the top level
   *   and shared by both the Journey Client and the OIDC client
   * - oidcClient.clientId: the OAuth 2.0 client registered in Ping AM
   * - oidcClient.redirectUri: URI this app redirects to after OAuth authorization
   * - oidcClient.scope: the OAuth 2.0 scopes requested from Ping AM
   *
   * `configure()` is async — it resolves only once the OIDC client is
   * constructed. Awaiting it before `user.tokens().get()` guarantees the token
   * fetch never races the null-client window, so ProtectedRoute sees the correct
   * auth state on the very first paint (no sign-in flash on reload).
   ************************************************************************* */
  await configure({
    wellknown: WELLKNOWN_URL,
    oidcClient: {
      clientId: WEB_OAUTH_CLIENT,
      redirectUri: `${window.location.origin}/callback.html`,
      scope: SCOPE,
    },
  });

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
