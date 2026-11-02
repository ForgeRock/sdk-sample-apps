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
 * Selectable sample app client profile.
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
  /**
   * Where the profile's configuration came from: a bundled
   * `assets/configs/*.json` file or a custom config created in the app.
   */
  source: 'json' | 'custom';
  /**
   * Configuration kind and the config it was built from. Used to duplicate or
   * edit the profile.
   */
  kind?: ConfigKind;
  unifiedConfig?: UnifiedConfig;
  /**
   * Custom entry id (custom profiles) or file name (JSON profiles).
   */
  presetId?: string;
  /**
   * Releases clients built lazily for the profile; they are rebuilt on next
   * use.
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

const profileCache = new WeakMap<ConfigPreset, SampleAppClientProfile[]>();

const createWebProfile = (
  preset: ConfigPreset,
): SampleAppClientProfile | undefined => {
  const { name, config } = preset;
  const { oidc } = config;
  if (!oidc) {
    return undefined;
  }
  const storageId = storageIdFor(`${preset.source}-${preset.id}`);
  const logLevel = toLogLevel(config.log);
  const oidcClientConfig: OidcClientConfig = {
    ...oidc,
    ios: { browserType: 'authSession', browserMode: 'login' },
  };
  const client = lazyResource(
    () => {
      const base = createOidcClient({
        ...oidcClientConfig,
        storage: configureOidcStorage({
          android: {
            fileName: `json-${storageId}-oidc`,
            keyAlias: `json.${storageId}.oidc`,
            strongBoxPreferred: true,
            cacheStrategy: CacheStrategy.CACHE_ON_FAILURE,
          },
          ios: {
            account: `com.pingidentity.rnsampleapp.oidc.json.${storageId}`,
            encryptor: true,
            cacheable: true,
          },
        }),
        logger: logLevel ? logger({ level: logLevel }) : appLogger,
      });
      return { base, web: createOidcWebClient(base) };
    },
    async ({ base, web }) => {
      await web.dispose();
      await base.dispose();
    },
  );
  return {
    key: `${preset.source}-oidc-${preset.id}`,
    name,
    host: hostnameFrom(oidc.discoveryEndpoint),
    environment: 'OIDC',
    get oidcClient() {
      return client.get().web;
    },
    oidcClientConfig,
    source: preset.source,
    kind: 'web',
    presetId: preset.id,
    unifiedConfig: config,
    dispose: () => client.dispose(),
  };
};

/**
 * Builds the OIDC Web profile a preset applies to. Clients are created on
 * first use, and the result is cached per preset object.
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
  const profiles = preset.kinds.includes('web')
    ? [createWebProfile(preset)].filter(
        (profile): profile is SampleAppClientProfile => !!profile,
      )
    : [];
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
