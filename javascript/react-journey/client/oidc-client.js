/*
 * ping-sample-web-react-journey
 *
 * oidc-client.js
 *
 * Copyright (c) 2026 Ping Identity Ping Identity Corporation. All rights reserved.
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { createContext, useContext } from 'react';

const OidcContext = createContext(null);

/**
 * @function useOidcClient - A custom hook to access the OIDC client from React Context
 * @returns - An OIDC client if it exists otherwise an error
 */
export function useOidcClient() {
  const client = useContext(OidcContext);
  if (!client) {
    throw new Error('useOidcClient must be used within OidcProvider');
  }
  return client;
}

/**
 * @function OidcProvider - A React Context provider for the OIDC client
 * @param - The OIDC client and children
 * @returns - The React Context provider
 */
export function OidcProvider({ client, children }) {
  return <OidcContext.Provider value={client}>{children}</OidcContext.Provider>;
}
