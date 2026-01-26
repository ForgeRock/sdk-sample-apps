/*
 * ping-sample-web-react-journey
 *
 * index.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import Router from './router';
import { CONFIG, INIT_PROTECT, PINGONE_ENV_ID } from './constants';
import Loading from './components/utilities/loading';
import { initTheme, ThemeContext } from './context/theme.context';
import { useInitOidcState, OidcContext } from './context/oidc.context';
import { useInitProtect, ProtectContext } from './context/protect.context';

/**
 * This import will produce a separate CSS file linked in the index.html
 * Webpack will detect this and transpile, process and generate the needed CSS file
 */
import './styles/index.scss';

const urlParams = new URLSearchParams(window.location.search);
const protectInitMode = INIT_PROTECT || urlParams.get('initProtect');

/**
 * Initialize the React application
 */
(async function initAndHydrate() {
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
    const oidcState = useInitOidcState(CONFIG);
    const protectState = useInitProtect({ envId: PINGONE_ENV_ID });

    const [{ oidcClient }] = oidcState;
    const [protectApi] = protectState;
    if (!oidcClient || (protectInitMode === 'bootstrap' && !protectApi)) {
      return (
        <ThemeContext.Provider value={theme}>
          <Loading message="Initializing application..." />
        </ThemeContext.Provider>
      );
    } else {
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
  }

  const rootEl = document.getElementById('root');
  const root = ReactDOM.createRoot(rootEl);

  // Mounts the React app to the existing root element
  root.render(<Init />);
})();
