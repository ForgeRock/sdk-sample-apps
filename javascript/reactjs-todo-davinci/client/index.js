/*
 * ping-sample-web-react-davinci
 *
 * index.js
 *
 * Copyright (c) 2025 - 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import Router from './router';
import { CONFIG, INIT_PROTECT, PINGONE_ENV_ID } from './constants';
import Loading from './components/utilities/loading';
import { initTheme, ThemeContext } from './context/theme.context.js';
import { useInitOidcState, OidcContext } from './context/oidc.context';
import { useInitProtect, ProtectContext } from './context/protect.context.js';

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
  function Init() {
    /**
     * This leverages React's Context API to share state across components
     * without prop drilling. Each concern has its own dedicated context:
     * OidcContext for auth state, ProtectContext for risk evaluation,
     * and ThemeContext for theming.
     *
     * If context state becomes a more complex function of the app,
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

  const rootEl = document.getElementById('root');
  const root = ReactDOM.createRoot(rootEl);

  // Mounts the React app to the existing root element
  root.render(<Init />);
})();
