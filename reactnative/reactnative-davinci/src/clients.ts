/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { DaVinciConfig } from '@ping-identity/rn-davinci';
import {
  createOidcDeviceClient,
  type OidcDeviceClient,
} from '@ping-identity/rn-oidc';
import { logger } from '@ping-identity/rn-logger';
import { CacheStrategy, configureOidcStorage } from '@ping-identity/rn-storage';
import { lazyResource } from './config/lazyResource';
import { loadJsonConfigPresets } from './config/loadConfigs';
import {
  bundledPreset,
  type ConfigKind,
  type ConfigPreset,
} from './config/customConfigs';
import { toLogLevel, type UnifiedConfig } from './config/unifiedConfig';

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
 * Supported sample app configuration groups.
 */
export type SampleConfigGroup = 'DaVinci' | 'Auth Grant';

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
   * Device authorization client bound to this profile. Present only for
   * `Auth Grant` group profiles.
   */
  deviceAuthClient?: OidcDeviceClient;
  /**
   * Device authorization configuration displayed by the Auth Grant section.
   * Present only for `Auth Grant` group profiles.
   */
  deviceAuthConfig?: DeviceAuthConfig;
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
   * DaVinci client configuration. Present only for `DaVinci` group profiles.
   */
  daVinciConfig?: DaVinciConfig;
  /**
   * Redirect URI used by external identity provider (social login) flows.
   * Present only for `DaVinci` group profiles.
   */
  redirectUri?: string;
  /**
   * Releases clients built lazily for the profile. Present only on JSON
   * profiles, whose clients are rebuilt on next use.
   */
  dispose?: () => Promise<void>;
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

const storageIdFor = (presetName: string): string =>
  presetName.replace(/[^A-Za-z0-9]/g, '_');

const loggerFor = (config: UnifiedConfig) => {
  const level = toLogLevel(config.log);
  return level ? logger({ level }) : appLogger;
};

const profileCache = new WeakMap<ConfigPreset, SampleAppClientProfile[]>();

const createDaVinciProfile = (
  preset: ConfigPreset,
): SampleAppClientProfile | undefined => {
  const { name, config } = preset;
  const { oidc } = config;
  if (!oidc) {
    return undefined;
  }
  const storageId = storageIdFor(`${preset.source}-${preset.id}`);
  const { openId: _deviceOnlyOverrides, ...daVinciOidc } = oidc;
  return {
    key: `${preset.source}-davinci-${preset.id}`,
    group: 'DaVinci',
    name,
    host: hostnameFrom(oidc.discoveryEndpoint),
    environment: 'PingOne',
    source: preset.source,
    kind: 'davinci',
    presetId: preset.id,
    unifiedConfig: config,
    redirectUri: oidc.redirectUri,
    daVinciConfig: {
      timeout: config.timeout,
      logger: loggerFor(config),
      modules: {
        oidc: {
          ...daVinciOidc,
          storage: configureOidcStorage({
            android: {
              fileName: `json-${storageId}-davinci`,
              keyAlias: `json.${storageId}.davinci`,
              strongBoxPreferred: true,
              cacheStrategy: CacheStrategy.CACHE_ON_FAILURE,
            },
            ios: {
              account: `com.pingidentity.rnsampleapp.davinci.json.${storageId}`,
              encryptor: true,
              cacheable: true,
            },
          }),
        },
      },
    },
  };
};

const createDeviceAuthProfile = (
  preset: ConfigPreset,
): SampleAppClientProfile | undefined => {
  const { name, config } = preset;
  const { oidc } = config;
  if (!oidc) {
    return undefined;
  }
  const storageId = storageIdFor(`${preset.source}-${preset.id}`);
  const deviceAuthConfig: DeviceAuthConfig = {
    clientId: oidc.clientId,
    discoveryEndpoint: oidc.discoveryEndpoint,
    scopes: oidc.scopes,
    display: name,
    acrValues: oidc.acrValues ?? '',
  };
  const client = lazyResource(
    () =>
      createOidcDeviceClient({
        ...oidc,
        storage: configureOidcStorage({
          android: {
            fileName: `json-${storageId}-device-auth`,
            keyAlias: `json.${storageId}.device.auth`,
            strongBoxPreferred: true,
            cacheStrategy: CacheStrategy.NO_CACHE,
          },
          ios: {
            account: `com.pingidentity.rnsampleapp.davinci.json.${storageId}.device.auth`,
            encryptor: true,
            cacheable: false,
          },
        }),
        logger: loggerFor(config),
      }),
    value => value.dispose(),
  );
  return {
    key: `${preset.source}-dag-${preset.id}`,
    group: 'Auth Grant',
    name,
    host: hostnameFrom(oidc.discoveryEndpoint),
    environment: 'PingOne',
    source: preset.source,
    kind: 'deviceAuth',
    presetId: preset.id,
    unifiedConfig: config,
    get deviceAuthClient() {
      return client.get();
    },
    deviceAuthConfig,
    dispose: () => client.dispose(),
  };
};

/**
 * Builds the DaVinci and Auth Grant profiles a preset applies to. Clients are
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
      kind === 'davinci'
        ? createDaVinciProfile(preset)
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
