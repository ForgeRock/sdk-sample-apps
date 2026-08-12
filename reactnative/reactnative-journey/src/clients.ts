/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { createJourneyClient } from '@ping-identity/rn-journey';
import type { JourneyClient } from '@ping-identity/rn-journey';
import Config from 'react-native-config';

import { logger } from '@ping-identity/rn-logger';
import {
  CacheStrategy,
  configureSessionStorage,
} from '@ping-identity/rn-storage';

/**
 * Normalized Journey OAuth scopes sourced from `JOURNEY_SCOPES`.
 */
const journeyScopes = (Config.JOURNEY_SCOPES ?? '')
  .split(',')
  .map(item => item.trim())
  .filter(Boolean);

/**
 * Base Journey module configuration resolved directly from environment
 * variables.
 */
export const journeyConfig = {
  serverUrl: Config.JOURNEY_SERVER_URL!,
  realm: Config.JOURNEY_REALM!,
  cookie: Config.JOURNEY_COOKIE!,
  clientId: Config.JOURNEY_CLIENT_ID!,
  discoveryEndpoint: Config.JOURNEY_DISCOVERY_ENDPOINT!,
  redirectUri: Config.JOURNEY_REDIRECT_URI!,
  scopes: journeyScopes,
};

/**
 * Session storage handle used by the Journey client module.
 */
const journeySessionStorageClient1 = configureSessionStorage({
  android: {
    fileName: 'journey_client_one_session_store',
    keyAlias: 'journey.client.one.session',
    cacheStrategy: CacheStrategy.NO_CACHE,
  },
  ios: {
    account: 'com.pingidentity.rnsampleapp.journey.client.one',
    encryptor: true,
    cacheable: false,
  },
});

/**
 * Shared logger instance used by sample clients.
 */
const appLogger = logger({ level: 'debug' });

/**
 * Journey-only client for validating flows without OIDC module composition.
 *
 * This mirrors native Journey setup where only `serverUrl` is configured.
 */
export const journeyOnlyClient = createJourneyClient({
  serverUrl: journeyConfig.serverUrl,
});

/**
 * Primary Journey client used by the sample app login flows.
 *
 * The client is configured with OIDC and session modules so it can handle
 * end-to-end Journey interactions, including token exchange and persisted
 * session continuity across app restarts.
 */
export const loginClient = createJourneyClient({
  timeout: 10000,
  serverUrl: journeyConfig.serverUrl,
  realm: journeyConfig.realm,
  cookie: journeyConfig.cookie,
  logger: appLogger,
  modules: {
    oidc: {
      clientId: journeyConfig.clientId,
      discoveryEndpoint: journeyConfig.discoveryEndpoint,
      redirectUri: journeyConfig.redirectUri,
      scopes: journeyConfig.scopes,
    },
    session: {
      storage: journeySessionStorageClient1,
    },
  },
});

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
   * Display-only journey/service label shown in configuration UI.
   */
  environment: string;
  /**
   * Journey client bound to the profile.
   */
  journeyClient: JourneyClient;
  /**
   * Redirect URI used by Journey external IdP integrations.
   */
  externalIdpRedirectUri: string;
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
    key: 'journey-default',
    name: 'Journey Test Config',
    host: hostnameFrom(journeyConfig.serverUrl),
    environment: journeyConfig.realm,
    journeyClient: loginClient,
    externalIdpRedirectUri: journeyConfig.redirectUri,
  },
  {
    key: 'journey-only',
    name: 'Journey Only',
    host: hostnameFrom(journeyConfig.serverUrl),
    environment: journeyConfig.realm,
    journeyClient: journeyOnlyClient,
    externalIdpRedirectUri: journeyConfig.redirectUri,
  },
];

/**
 * Default selected profile key for sample app boot.
 */
export const DEFAULT_SAMPLE_APP_CLIENT_PROFILE_KEY =
  sampleAppClientProfiles[0].key;
