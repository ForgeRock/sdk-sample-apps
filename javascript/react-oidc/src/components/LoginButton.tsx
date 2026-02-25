/*
 * LoginButton.tsx
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import type { OidcClient, UserInfoResponse } from '@forgerock/oidc-client/types';

export default function LoginButton({
  oidcClient,
  setIsAuthenticated,
  setUser,
  setError,
}: {
  oidcClient: OidcClient | null;
  setIsAuthenticated: (isAuthenticated: boolean) => void;
  setUser: (user: UserInfoResponse) => void;
  setError: (error: string) => void;
}) {
  async function handleLogin() {
    if (!oidcClient || 'error' in oidcClient) {
      setError(`OIDC Client Error: ${oidcClient?.error || 'Client not initialized'}`);
      return;
    }

    // If the user is already logged in, display user info
    const tokens = await oidcClient.token.get();

    if ('accessToken' in tokens) {
      const user = await oidcClient.user.info();
      if ('error' in user) {
        setError(`User info error: ${user.error}`);
        return;
      }
      setUser(user);
      setIsAuthenticated(true);
      return;
    }

    // Otherwise redirect to the authorization server for centralized login
    const authorizeUrl = await oidcClient.authorize.url();
    if (typeof authorizeUrl !== 'string' && 'error' in authorizeUrl) {
      setError(`Error constructing authorize URL: ${authorizeUrl.error}`);
      return;
    }

    window.location.assign(authorizeUrl);
  }

  return (
    <button onClick={handleLogin} disabled={!oidcClient || 'error' in oidcClient}>
      Login
    </button>
  );
}
