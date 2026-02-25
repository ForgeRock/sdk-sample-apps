/*
 * LogoutButton.tsx
 *
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import type { OidcClient } from '@forgerock/oidc-client/types';

export default function LogoutButton({
  oidcClient,
  setIsAuthenticated,
  setError,
}: {
  oidcClient: OidcClient | null;
  setIsAuthenticated: (isAuthenticated: boolean) => void;
  setError: (error: string) => void;
}) {
  async function handleLogout() {
    if (!oidcClient || 'error' in oidcClient) {
      setError(`OIDC Client Error: ${oidcClient?.error || 'Client not initialized'}`);
      return;
    }

    const response = await oidcClient.user.logout();
    if ('error' in response) {
      setError(`Logout error: ${response.error}`);
      return;
    }

    setIsAuthenticated(false);

    // Reload the page after a successful logout
    window.location.assign(window.location.origin);
  }

  return (
    <button onClick={handleLogout} disabled={!oidcClient || 'error' in oidcClient}>
      Logout
    </button>
  );
}
