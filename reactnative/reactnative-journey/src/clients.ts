/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { createJourneyClient } from '@ping-identity/rn-journey';
import { createOidcDeviceClient } from '@ping-identity/rn-oidc';
import type {
  OidcDeviceClient,
  OidcOpenIdConfiguration,
} from '@ping-identity/rn-oidc';
import type { JourneyClient } from '@ping-identity/rn-journey';

import { logger } from '@ping-identity/rn-logger';
import {
  CacheStrategy,
  configureOidcStorage,
  configureSessionStorage,
} from '@ping-identity/rn-storage';
import { lazyResource } from './config/lazyResource';
import { loadJsonConfigPresets } from './config/loadConfigs';
import {
  bundledPreset,
  type ConfigKind,
  type ConfigPreset,
} from './config/customConfigs';
import {
  toLogLevel,
  type UnifiedConfig,
  type UnifiedJourneyConfig,
  type UnifiedOidcConfig,
} from './config/unifiedConfig';

/**
 * Shared logger instance used by sample clients.
 */
const appLogger = logger({ level: 'debug' });

/**
 * Device Authorization Grant configuration shape displayed by the Auth Grant
 * section of the Configuration screen.
 */
export type DeviceAuthConfig = {
  clientId: string;
  discoveryEndpoint: string;
  scopes: string[];
  display: string;
  acrValues: string;
  /**
   * Optional OpenID endpoint overrides.
   *
   * @remarks
   * Needed when the provider's discovery document omits an endpoint the
   * device authorization flow requires (for example, Advanced Identity
   * Cloud's discovery document has no `device_authorization_endpoint`).
   */
  openId?: OidcOpenIdConfiguration;
};

/**
 * Device client used while no Auth Grant configuration is selected, so the
 * provider tree stays mounted. It restores no user and rejects authorization
 * with an actionable message.
 */
export const unconfiguredDeviceAuthClient: OidcDeviceClient = {
  id: 'unconfigured-device-auth-client',
  async authorize() {
    throw new Error('Select an Auth Grant configuration first.');
  },
  async user() {
    return null;
  },
  async dispose() {},
};

/**
 * Journey server address and session cookie name for the selected profile.
 */
export type JourneyConnection = {
  serverUrl: string;
  cookie?: string;
};

/**
 * Supported sample app configuration groups.
 */
export type SampleConfigGroup = 'Journey' | 'Auth Grant';

/**
 * Runtime-selectable sample app client profile.
 */
export type SampleAppClientProfile = {
  /**
   * Stable profile key used by the configuration selector.
   */
  key: string;
  /**
   * UI group heading for this profile.
   */
  group: SampleConfigGroup;
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
   * Journey client bound to the profile. Present only for `Journey` group
   * profiles.
   */
  journeyClient?: JourneyClient;
  /**
   * Where the profile's configuration came from: a bundled
   * `assets/configs/*.json` file or a custom config created in the app.
   */
  source: 'json' | 'custom';
  /**
   * Configuration kind and the config it was built from, for JSON and custom
   * profiles. Used to duplicate or edit the profile.
   */
  kind?: ConfigKind;
  unifiedConfig?: UnifiedConfig;
  /**
   * Custom entry id (custom profiles) or file name (JSON profiles).
   */
  presetId?: string;
  /**
   * Server address and session cookie used by device management calls.
   * Present only for `Journey` group profiles.
   */
  connection?: JourneyConnection;
  /**
   * Releases clients built lazily for the profile; they are rebuilt on next
   * use.
   */
  dispose?: () => Promise<void>;
  /**
   * Redirect URI used by Journey external IdP integrations.
   */
  externalIdpRedirectUri: string;
  /**
   * Device authorization client bound to this profile. Present only for
   * `Auth Grant` group profiles.
   */
  deviceAuthClient?: OidcDeviceClient;
  /**
   * Device authorization configuration displayed by the Auth Grant section.
   * Present only for `Auth Grant` group profiles.
   */
  deviceAuthConfig?: DeviceAuthConfig;
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

let activeJourneyConnection: JourneyConnection | undefined;

/**
 * Records the connection of the selected Journey profile for device calls.
 *
 * @param connection Server address and cookie name of the selected profile.
 */
export function setActiveJourneyConnection(
  connection: JourneyConnection | undefined,
): void {
  activeJourneyConnection = connection;
}

/**
 * Connection of the selected Journey profile.
 *
 * @returns Server address and cookie name, or `undefined` when no Journey
 * configuration is selected.
 */
export function getActiveJourneyConnection(): JourneyConnection | undefined {
  return activeJourneyConnection;
}

const DEFAULT_REDIRECT_URI = 'org.forgerock.demo://oauth2redirect';

const storageIdFor = (presetName: string): string =>
  presetName.replace(/[^A-Za-z0-9]/g, '_');

const loggerFor = (config: UnifiedConfig) => {
  const level = toLogLevel(config.log);
  return level ? logger({ level }) : appLogger;
};

const createJourneyClientFromPreset = (
  presetName: string,
  config: UnifiedConfig,
  journey: UnifiedJourneyConfig,
): JourneyClient => {
  const storageId = storageIdFor(presetName);
  return createJourneyClient({
    timeout: config.timeout,
    serverUrl: journey.serverUrl,
    realm: journey.realm,
    cookie: journey.cookie,
    logger: loggerFor(config),
    modules: {
      oidc: config.oidc,
      session: {
        storage: configureSessionStorage({
          android: {
            fileName: `journey_json_${storageId}_session_store`,
            keyAlias: `journey.json.${storageId}.session`,
            cacheStrategy: CacheStrategy.NO_CACHE,
          },
          ios: {
            account: `com.pingidentity.rnsampleapp.journey.json.${storageId}`,
            encryptor: true,
            cacheable: false,
          },
        }),
      },
    },
  });
};

const createDeviceClientFromPreset = (
  presetName: string,
  config: UnifiedConfig,
  oidc: UnifiedOidcConfig,
): OidcDeviceClient => {
  const storageId = storageIdFor(presetName);
  return createOidcDeviceClient({
    ...oidc,
    storage: configureOidcStorage({
      android: {
        fileName: `json-${storageId}-device-auth`,
        keyAlias: `json.${storageId}.device.auth`,
        strongBoxPreferred: true,
        cacheStrategy: CacheStrategy.NO_CACHE,
      },
      ios: {
        account: `com.pingidentity.rnsampleapp.json.${storageId}.device.auth`,
        encryptor: true,
        cacheable: false,
      },
    }),
    logger: loggerFor(config),
  });
};

const profileCache = new WeakMap<ConfigPreset, SampleAppClientProfile[]>();

const createJourneyProfile = (
  preset: ConfigPreset,
): SampleAppClientProfile | undefined => {
  const { journey, oidc } = preset.config;
  if (!journey) {
    return undefined;
  }
  const storageKey = `${preset.source}-${preset.id}`;
  const client = lazyResource(
    () => createJourneyClientFromPreset(storageKey, preset.config, journey),
    value => value.dispose(),
  );
  return {
    key: `${preset.source}-journey-${preset.id}`,
    group: 'Journey',
    name: preset.name,
    host: hostnameFrom(journey.serverUrl),
    environment: journey.realm ?? 'default',
    get journeyClient() {
      return client.get();
    },
    source: preset.source,
    kind: 'journey',
    presetId: preset.id,
    unifiedConfig: preset.config,
    connection: { serverUrl: journey.serverUrl, cookie: journey.cookie },
    dispose: () => client.dispose(),
    externalIdpRedirectUri: oidc?.redirectUri ?? DEFAULT_REDIRECT_URI,
  };
};

const createDeviceAuthProfile = (
  preset: ConfigPreset,
): SampleAppClientProfile | undefined => {
  const { journey, oidc } = preset.config;
  if (!oidc) {
    return undefined;
  }
  const storageKey = `${preset.source}-${preset.id}`;
  const deviceAuthConfig: DeviceAuthConfig = {
    clientId: oidc.clientId,
    discoveryEndpoint: oidc.discoveryEndpoint,
    scopes: oidc.scopes,
    display: preset.name,
    acrValues: oidc.acrValues ?? '',
    openId: oidc.openId,
  };
  const client = lazyResource(
    () => createDeviceClientFromPreset(storageKey, preset.config, oidc),
    value => value.dispose(),
  );
  return {
    key: `${preset.source}-dag-${preset.id}`,
    group: 'Auth Grant',
    name: preset.name,
    host: hostnameFrom(oidc.discoveryEndpoint),
    environment: journey?.realm ?? 'default',
    source: preset.source,
    kind: 'deviceAuth',
    presetId: preset.id,
    unifiedConfig: preset.config,
    dispose: () => client.dispose(),
    externalIdpRedirectUri: oidc.redirectUri,
    get deviceAuthClient() {
      return client.get();
    },
    deviceAuthConfig,
  };
};

/**
 * Builds the Journey and Auth Grant profiles a preset applies to. Clients are
 * created on first use, and the result is cached per preset object.
 *
 * @param preset Bundled or custom preset.
 * @returns Profiles for the kinds this sample supports.
 */
export function createPresetProfiles(
  preset: ConfigPreset,
): readonly SampleAppClientProfile[] {
  const cached = profileCache.get(preset);
  if (cached) {
    return cached;
  }
  const profiles = preset.kinds
    .map(kind =>
      kind === 'journey'
        ? createJourneyProfile(preset)
        : kind === 'deviceAuth'
          ? createDeviceAuthProfile(preset)
          : undefined,
    )
    .filter((profile): profile is SampleAppClientProfile => !!profile);
  profileCache.set(preset, profiles);
  return profiles;
}

/**
 * Selectable sample app configurations shown in the Configuration screen: the
 * bundled JSON presets. Custom configs are added at runtime through
 * {@link createPresetProfiles}.
 */
export const sampleAppClientProfiles: readonly SampleAppClientProfile[] =
  loadJsonConfigPresets(message => appLogger.warn(message)).flatMap(preset =>
    createPresetProfiles(bundledPreset(preset)),
  );
