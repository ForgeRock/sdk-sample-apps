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
   * - serverConfig.wellknown: the OpenID Connect discovery URL, shared by both
   *   the Journey Client and the OIDC client
   * - logger: log config forwarded to both clients — logger.level sets verbosity
   *   ('none'|'error'|'warn'|'info'|'debug'); logger.custom redirects log output
   * - middleware: request middleware forwarded to both journey and OIDC clients
   * - storage: top-level token storage config — type ('localStorage'|
   *   'sessionStorage'|'custom'), required name, and optional prefix
   * - oidcClient.clientId: the OAuth 2.0 client registered in Ping AM
   * - oidcClient.redirectUri: URI this app redirects to after OAuth authorization
   * - oidcClient.scope: the OAuth 2.0 scopes requested from Ping AM
   * - oidcClient.oauthThreshold: ms before expiry to trigger background renewal
   * - oidcClient.par: use Pushed Authorization Requests (true | false)
   * - oidcClient.loginHint: pre-fills the login identifier on the authorize request
   * - oidcClient.acrValues: space-separated ACR values requesting specific auth strength (e.g. MFA)
   * - oidcClient.query: arbitrary key/value pairs appended to the authorize request URL
   *
   * `configure()` is async — it resolves only once the OIDC client is
   * constructed. Awaiting it before `user.tokens().get()` guarantees the token
   * fetch never races the null-client window, so ProtectedRoute sees the correct
   * auth state on the very first paint (no sign-in flash on reload).
   ************************************************************************* */
  if (DEBUGGER) debugger;

  const sessionId = crypto.randomUUID();
  const JOURNEY_ACTIONS = ['JOURNEY_START', 'JOURNEY_NEXT', 'JOURNEY_TERMINATE'];

  await configure({
    serverConfig: { wellknown: WELLKNOWN_URL },
    logger: { level: process.env.LOG_LEVEL || 'error' },
    middleware: [journeyMiddleware, oidcMiddleware],
    storage: {
      type: 'sessionStorage',
      name: WEB_OAUTH_CLIENT,
    },
    oidcClient: {
      clientId: WEB_OAUTH_CLIENT,
      redirectUri: `${window.location.origin}/callback.html`,
      scope: SCOPE,
      oauthThreshold: 60000,
      par: false,
      loginHint: 'demo@example.com',
      acrValues: 'urn:acr:example',
      query: { ui_locales: 'en-US' },
    },
  });

  let isAuthenticated = false;
  try {
    const event = await user.tokens().get();
    isAuthenticated = !!event?.response?.accessToken;
  } catch (err) {
    // No tokens in storage — user is unauthenticated, not an error
  }

  function journeyMiddleware(req, action, next) {
    if (JOURNEY_ACTIONS.includes(action.type)) {
      req.headers.set('X-Session-ID', sessionId);
      if (process.env.LOG_LEVEL === 'debug') {
        console.log('[journey-middleware]', action.type, req.url.href);
      }
    }
    next();
  }

  function oidcMiddleware(req, action, next) {
    if (!JOURNEY_ACTIONS.includes(action.type)) {
      req.headers.set('X-Session-ID', sessionId);
      if (process.env.LOG_LEVEL === 'debug') {
        console.log('[oidc-middleware]', action.type, req.url.href);
      }
    }
    next();
  }

  /**
   * @function Init - Initializes React, State
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
