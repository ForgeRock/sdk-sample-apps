/*
 * main.js
 *
 * Copyright (c) 2025 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import './style.css';
import { oidc } from '@forgerock/oidc-client';

/**
 * Check URL for query parameters
 */
const url = new URL(document.location);
const params = url.searchParams;
const authCode = params.get('code');
const state = params.get('state');

const displayError = (errorMessage) => {
  document.querySelector('#Error span').innerHTML = errorMessage;
  document.querySelector('#Error').classList.add('active');
};

(async () => {
  const oidcClient = await oidc({
    config: {
      clientId: import.meta.env.VITE_WEB_OAUTH_CLIENT, // e.g. 'ForgeRockSDKClient' or PingOne Services Client GUID
      redirectUri: `${window.location.origin}/`, // Redirect back to your app, e.g. 'https://localhost:8443' or the domain your app is served.
      scope: import.meta.env.VITE_SCOPE, // e.g. 'openid profile email address phone revoke' When using PingOne services `revoke` scope is required
      serverConfig: {
        wellknown: import.meta.env.VITE_WELLKNOWN_URL,
        timeout: import.meta.env.VITE_TIMEOUT, // Any value between 3000 to 5000 is good, this impacts the redirect time to login. Change that according to your needs.
      },
    },
  });

  if ('error' in oidcClient) {
    displayError(oidcClient.error);
  }

  // Show only the view for this handler
  const showStep = (handler) => {
    document.querySelectorAll('#steps > *').forEach((x) => x.classList.remove('active'));
    const panel = document.getElementById(handler);
    if (!panel) {
      console.error(`No panel with ID "${handler}"" found`);
      return false;
    }
    document.getElementById(handler).classList.add('active');
    return true;
  };

  const showUser = (user) => {
    document.querySelector('#User pre').innerHTML = JSON.stringify(user, null, 2);
    const panel = document.querySelector('#User');
    panel.querySelector('#logout').addEventListener('click', () => {
      logout();
    });
    showStep('User');
  };

  const logout = async () => {
    const response = await oidcClient.user.logout();
    if ('error' in response) {
      displayError(response.error);
      return;
    }

    // Reload the page after a successful logout
    window.location.assign(window.location.origin);
  };

  const authorize = async (code, state) => {
    /**
     * When the user returns to this app after successfully logging in,
     * the URL will include code and state query parameters that need to
     * be passed in to complete the OAuth flow giving the user access
     */
    console.log('State:' + state + ' code:' + code);

    const tokens = await oidcClient.token.exchange(code, state);
    console.log('Tokens:', tokens);
    if ('error' in tokens) {
      displayError(tokens.error);
      return;
    }

    const user = await oidcClient.user.info();
    if ('error' in user) {
      displayError(user.error);
      return;
    }

    showUser(user);
  };

  document.querySelector('#loginBtn')?.addEventListener('click', async () => {
    const authorizeUrl = await oidcClient.authorize.url();
    if (typeof authorizeUrl !== 'string' && 'error' in authorizeUrl) {
      displayError(authorizeUrl.error);
      return;
    }

    // Redirect to the authorization server for centralized login
    window.location.assign(authorizeUrl);
  });

  /**
   * If the URL has state and authCode as query parameters, then the user
   * returned back here after successfully logging, so call authorize with
   * the values
   */
  if (state && authCode) {
    await authorize(authCode, state);
  }
})();
