/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import {
  createOidcClient,
  createOidcWebClient,
  type OidcClientConfig,
  type OidcWebClient,
} from '@ping-identity/rn-oidc';
import Config from 'react-native-config';

import { logger } from '@ping-identity/rn-logger';
import { CacheStrategy, configureOidcStorage } from '@ping-identity/rn-storage';

/**
 * Normalized Advanced Identity Cloud OAuth scopes sourced from `AIC_SCOPES`.
 */
const aicScopes = (Config.AIC_SCOPES ?? '')
  .split(',')
  .map(item => item.trim())
  .filter(Boolean);

/**
 * Normalized PingOne OAuth scopes sourced from `PINGONE_SCOPES`.
 */
const pingOneScopes = (Config.PINGONE_SCOPES ?? '')
  .split(',')
  .map(item => item.trim())
  .filter(Boolean);

/**
 * Shared logger instance used by sample clients.
 */
const appLogger = logger({ level: 'debug' });

/**
 * OIDC client configuration for the Advanced Identity Cloud / PingAM tenant.
 */
export const forgeblockOidcClientConfig: OidcClientConfig = {
  clientId: Config.AIC_CLIENT_ID!,
  discoveryEndpoint: Config.AIC_DISCOVERY_ENDPOINT!,
  redirectUri: Config.AIC_REDIRECT_URI!,
  scopes: aicScopes,
  ios: {
    browserType: 'authSession',
    browserMode: 'login',
  },
};

/**
 * PingOne OIDC client configuration mirrored from SDK test configuration.
 */
const pingOneOidcClientConfig: OidcClientConfig = {
  clientId: Config.PINGONE_CLIENT_ID!,
  discoveryEndpoint: Config.PINGONE_DISCOVERY_ENDPOINT!,
  redirectUri: Config.PINGONE_REDIRECT_URI!,
  scopes: pingOneScopes,
  acrValues: Config.PINGONE_ACR_VALUES!,
  ios: {
    browserType: 'authSession',
    browserMode: 'login',
  },
};

/**
 * OIDC storage handle used by the sample OIDC client.
 */
const sampleOidcStorage = configureOidcStorage({
  android: {
    fileName: 'ping-oidc',
    keyAlias: 'ping-oidc',
    strongBoxPreferred: true,
    cacheStrategy: CacheStrategy.CACHE_ON_FAILURE,
  },
  ios: {
    account: 'com.pingidentity.rnsampleapp.oidc.oidc',
    encryptor: true,
    cacheable: true,
  },
});

/**
 * Internal OIDC client instance for the Advanced Identity Cloud / PingAM tenant.
 */
const forgeblockOidcClient = createOidcClient({
  ...forgeblockOidcClientConfig,
  storage: sampleOidcStorage,
  logger: appLogger,
});

/**
 * Internal OIDC client instance for PingOne test-tenant validation.
 */
const pingOneOidcClient = createOidcClient({
  ...pingOneOidcClientConfig,
  storage: sampleOidcStorage,
  logger: appLogger,
});

/**
 * Web-capable OIDC client for the Advanced Identity Cloud / PingAM tenant.
 */
export const forgeblockOidcWebClient: OidcWebClient =
  createOidcWebClient(forgeblockOidcClient);

/**
 * Web-capable OIDC client for the PingOne test tenant profile.
 */
export const pingOneOidcWebClient: OidcWebClient =
  createOidcWebClient(pingOneOidcClient);

/**
 * Runtime-selectable sample app client profile.
 */
export type SampleAppClientProfile = {
  /**
   * Stable profile key used by the configuration selector.
   */
  key: string;
  /**
   * Human readable profile name.
   */
  name: string;
  /**
   * Display-only host label shown in configuration UI.
   */
  host: string;
  /**
   * Display-only environment label shown in configuration UI.
   */
  environment: string;
  /**
   * OIDC web client bound to the profile.
   */
  oidcClient: OidcWebClient;
  /**
   * OIDC client configuration displayed by the OIDC demo panel.
   */
  oidcClientConfig: OidcClientConfig;
};

/**
 * Extracts hostname text from URL-like values for concise UI labels.
 *
 * @param value URL string to parse.
 * @returns Hostname when parsable, otherwise original value.
 */
function hostnameFrom(value: string): string {
  const normalized = value.replace(/^https?:\/\//i, '');
  return normalized.split('/')[0] ?? value;
}

/**
 * Runtime-selectable sample app configurations shown in the Configuration screen.
 */
export const sampleAppClientProfiles: readonly SampleAppClientProfile[] = [
  {
    key: 'oidc-forgeblock',
    name: 'OIDC Forgeblock',
    host: hostnameFrom(forgeblockOidcClientConfig.discoveryEndpoint ?? ''),
    environment: 'Advanced Identity Cloud',
    oidcClient: forgeblockOidcWebClient,
    oidcClientConfig: forgeblockOidcClientConfig,
  },
  {
    key: 'oidc-pingone',
    name: 'OIDC PingOne',
    host: hostnameFrom(pingOneOidcClientConfig.discoveryEndpoint ?? ''),
    environment: Config.PINGONE_ENVIRONMENT_LABEL ?? 'PingOne',
    oidcClient: pingOneOidcWebClient,
    oidcClientConfig: pingOneOidcClientConfig,
  },
];

/**
 * Default selected profile key for sample app boot.
 */
export const DEFAULT_SAMPLE_APP_CLIENT_PROFILE_KEY =
  sampleAppClientProfiles[0].key;
