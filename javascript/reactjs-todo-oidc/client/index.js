/*
 * ping-sample-web-react-todo-oidc
 *
 * index.js
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import ReactDOM from 'react-dom/client';

import Loading from './components/utilities/loading';
import { OidcContext, useInitOidcState } from './context/oidc.context';
import { useInitProtect, ProtectContext } from './context/protect.context';
import { ThemeContext, initTheme } from './context/theme.context';
import Router from './router';
import { DEBUGGER, INIT_PROTECT, PINGONE_ENV_ID } from './constants';

/**
 * This import will produce a separate CSS file linked in the index.html
 * Webpack will detect this and transpile, process and generate the needed CSS file
 */
import './styles/index.scss';

if (DEBUGGER) debugger;
const urlParams = new URLSearchParams(window.location.search);
const protectInitMode = INIT_PROTECT || urlParams.get('initProtect');

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
  const rootEl = document.getElementById('root');

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
    const theme = initTheme();
    const oidcState = useInitOidcState();
    const protectState = useInitProtect({ envId: PINGONE_ENV_ID });
    const [{ oidcClient }] = oidcState;
    const [protectApi] = protectState;

    if (!oidcClient || (protectInitMode === 'bootstrap' && !protectApi)) {
      return (
        <ThemeContext.Provider value={theme}>
          <OidcContext.Provider value={oidcState}>
            <Loading message="Initializing application..." />
          </OidcContext.Provider>
        </ThemeContext.Provider>
      );
    }

    return (
      <ThemeContext.Provider value={theme}>
        <OidcContext.Provider value={oidcState}>
          <ProtectContext.Provider value={protectState}>
            <Router />
          </ProtectContext.Provider>
        </OidcContext.Provider>
      </ThemeContext.Provider>
    );
  }

  const root = ReactDOM.createRoot(rootEl);
  // Mounts the React app to the existing root element
  root.render(<Init />);
})();
