/*
 * Form.tsx
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import { useEffect, useRef, useState } from 'react';
import { oidc } from '@forgerock/oidc-client';
import type { OidcClient, OidcConfig, UserInfoResponse } from '@forgerock/oidc-client/types';
import LoginButton from './LoginButton';
import LogoutButton from './LogoutButton';
import UserInfo from './UserInfo';

/**
 * Check URL for query parameters
 */
const url = new URL(document.location.href);
const params = url.searchParams;
const authCode = params.get('code');
const authState = params.get('state');

export default function Form() {
  const [oidcClient, setOidcClient] = useState<OidcClient | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [user, setUser] = useState<UserInfoResponse | null>(null);
  const [error, setError] = useState<string>('');

  /**
   * An optional boolean ref used to prevent multiple authorization attempts during developement
   * when React Strict Mode is enabled
   */
  const authorizationStarted = useRef(false);

  useEffect(() => {
    async function initializeClient() {
      const config: OidcConfig = {
        clientId: import.meta.env.VITE_WEB_OAUTH_CLIENT, // e.g. 'WebOAuthClient' or PingOne Services Client GUID
        redirectUri: `${window.location.origin}/`, // Redirect back to your app, e.g. 'https://localhost:8443' or the domain your app is served.
        scope: import.meta.env.VITE_SCOPE, // e.g. 'openid profile email address phone revoke' When using PingOne services `revoke` scope is required
        serverConfig: {
          wellknown: import.meta.env.VITE_WELLKNOWN_URL,
        },
      };

      const client = await oidc({ config });
      if ('error' in client) {
        setError(`Error initializing OIDC client: ${client.error}`);
        setOidcClient(null);
      } else {
        setOidcClient(client);
      }
    }

    initializeClient();
  }, []);

  useEffect(() => {
    /**
     * When the user returns to this app after successfully logging in,
     * the URL will include code and state query parameters that need to
     * be passed in to complete the OAuth flow giving the user access
     */
    async function authorize(code: string, state: string) {
      if (!oidcClient || 'error' in oidcClient) {
        setError(`OIDC Client Error: ${oidcClient?.error || 'Client not initialized'}`);
        return;
      }

      if (!authorizationStarted.current) {
        authorizationStarted.current = true;

        const tokens = await oidcClient.token.exchange(code, state);
        if ('error' in tokens) {
          setError(`Token exchange error: ${tokens.error}`);
          return;
        }

        const user = await oidcClient.user.info();
        if ('error' in user) {
          setError(`User info error: ${user.error}`);
          return;
        }

        setUser(user);
        setIsAuthenticated(true);
      }
    }

    /**
     * If the URL has state and authCode as query parameters, then the user
     * returned back here after successfully logging, so call authorize with
     * the values
     */
    if (oidcClient && authState && authCode) {
      authorize(authCode, authState);
    }
  }, [oidcClient]);


    return (
      <div className="form">
        {!isAuthenticated && (
          <LoginButton
            oidcClient={oidcClient}
            setIsAuthenticated={setIsAuthenticated}
            setUser={setUser}
            setError={setError}
          />
        )}
        {isAuthenticated && (
          <>
            <UserInfo user={user} />
            <LogoutButton oidcClient={oidcClient} setIsAuthenticated={setIsAuthenticated} setError={setError} />
          </>
        )}
        {error && (<div className="error">
          <p><strong>Error: </strong>{error}</p>
          <button onClick={() => window.location.href = '/'}>Start Over</button>
          </div>)}
      </div>
    );
}
