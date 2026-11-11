/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { JsonConfigPreset } from './loadConfigs';
import { parseUnifiedConfig, type UnifiedConfig } from './unifiedConfig';

/**
 * Configuration categories, matching the cards of the native sample apps.
 */
export type ConfigKind = 'journey' | 'davinci' | 'web' | 'deviceAuth';

/**
 * Where a configuration comes from.
 */
export type ConfigSource = 'json' | 'custom';

/**
 * Text field shown in the add/edit form.
 */
export type FieldDef = {
  key: string;
  label: string;
  required?: boolean;
  hint?: string;
};

/**
 * Form values keyed by {@link FieldDef.key}.
 */
export type ConfigFields = Record<string, string>;

/**
 * A user-created configuration persisted by {@link useCustomConfigs}.
 */
export type CustomConfigEntry = {
  id: string;
  kind: ConfigKind;
  fields: ConfigFields;
};

/**
 * A configuration ready to become a profile, from a bundled file or a custom
 * entry. `kinds` lists the cards it appears in.
 */
export type ConfigPreset = {
  id: string;
  name: string;
  source: ConfigSource;
  config: UnifiedConfig;
  kinds: readonly ConfigKind[];
};

const NAME: FieldDef = { key: 'name', label: 'Name', required: true };
const CLIENT_ID: FieldDef = {
  key: 'clientId',
  label: 'Client ID',
  required: true,
};
const DISCOVERY: FieldDef = {
  key: 'discoveryEndpoint',
  label: 'Discovery endpoint',
  required: true,
};
const SCOPES: FieldDef = {
  key: 'scopes',
  label: 'Scopes',
  required: true,
  hint: 'Comma separated',
};
const REDIRECT: FieldDef = {
  key: 'redirectUri',
  label: 'Redirect URI',
  required: true,
};
const ACR: FieldDef = { key: 'acrValues', label: 'ACR values' };

/**
 * Form fields per configuration kind.
 */
export const CONFIG_FIELDS: Record<ConfigKind, readonly FieldDef[]> = {
  journey: [
    NAME,
    { key: 'serverUrl', label: 'Server URL', required: true },
    { key: 'realm', label: 'Realm' },
    { key: 'cookie', label: 'Cookie name' },
    CLIENT_ID,
    DISCOVERY,
    SCOPES,
    REDIRECT,
  ],
  davinci: [
    NAME,
    CLIENT_ID,
    DISCOVERY,
    SCOPES,
    REDIRECT,
    ACR,
    {
      key: 'protectEnvId',
      label: 'Protect env ID',
      hint: 'PingOne environment ID for Protect signals',
    },
  ],
  web: [NAME, CLIENT_ID, DISCOVERY, SCOPES, REDIRECT, ACR],
  deviceAuth: [
    NAME,
    CLIENT_ID,
    DISCOVERY,
    SCOPES,
    ACR,
    { key: 'authorizationEndpoint', label: 'Authorization endpoint' },
    { key: 'tokenEndpoint', label: 'Token endpoint' },
    { key: 'userinfoEndpoint', label: 'User info endpoint' },
    { key: 'endSessionEndpoint', label: 'End session endpoint' },
    { key: 'revocationEndpoint', label: 'Revocation endpoint' },
    {
      key: 'deviceAuthorizationEndpoint',
      label: 'Device authorization endpoint',
    },
  ],
};

/**
 * Display titles per kind.
 */
export const CONFIG_KIND_TITLES: Record<ConfigKind, string> = {
  journey: 'Journey',
  davinci: 'DaVinci',
  web: 'OIDC (Web)',
  deviceAuth: 'Auth Grant',
};

// The device authorization grant never redirects; the OIDC config still
// requires a value, so the placeholder used by the bundled files is reused.
const DEVICE_AUTH_REDIRECT_URI = 'app:/oauth2redirect';

const ENDPOINT_KEYS = [
  'authorizationEndpoint',
  'tokenEndpoint',
  'userinfoEndpoint',
  'endSessionEndpoint',
  'revocationEndpoint',
  'deviceAuthorizationEndpoint',
] as const;

const blankToUndefined = (value: string | undefined): string | undefined => {
  const trimmed = value?.trim();
  return trimmed ? trimmed : undefined;
};

/**
 * Kinds a bundled file appears under: a file with `journey` is a Journey
 * config, otherwise DaVinci; any file with `oidc` is also an OIDC Web config;
 * `openId` (or a DaVinci file) also yields an Auth Grant config.
 *
 * @param config Parsed bundled file.
 * @returns Kinds in display order.
 */
export function kindsForBundledConfig(config: UnifiedConfig): ConfigKind[] {
  const isDaVinci = !config.journey && !!config.oidc;
  return [
    ...(config.journey ? (['journey'] as const) : []),
    ...(isDaVinci ? (['davinci'] as const) : []),
    ...(config.oidc ? (['web'] as const) : []),
    ...(config.oidc?.openId || isDaVinci ? (['deviceAuth'] as const) : []),
  ];
}

/**
 * Converts a bundled file into a preset.
 *
 * @param preset File name and parsed config.
 * @returns Preset listed under the kinds the file applies to.
 */
export function bundledPreset(preset: JsonConfigPreset): ConfigPreset {
  return {
    id: preset.name,
    name: preset.name,
    source: 'json',
    config: preset.config,
    kinds: kindsForBundledConfig(preset.config),
  };
}

/**
 * Builds the unified config a form describes.
 *
 * @param kind Configuration kind.
 * @param fields Form values.
 * @returns Config usable to build clients.
 */
export function toUnifiedConfig(
  kind: ConfigKind,
  fields: ConfigFields,
): UnifiedConfig {
  const openId =
    kind === 'deviceAuth'
      ? Object.fromEntries(
          ENDPOINT_KEYS.map(key => [key, blankToUndefined(fields[key])]),
        )
      : undefined;
  return {
    journey:
      kind === 'journey'
        ? {
            serverUrl: fields.serverUrl.trim(),
            realm: blankToUndefined(fields.realm),
            cookie: blankToUndefined(fields.cookie),
          }
        : undefined,
    oidc: {
      clientId: fields.clientId.trim(),
      discoveryEndpoint: fields.discoveryEndpoint.trim(),
      scopes: (fields.scopes ?? '')
        .split(',')
        .map(item => item.trim())
        .filter(Boolean),
      redirectUri:
        kind === 'deviceAuth'
          ? DEVICE_AUTH_REDIRECT_URI
          : fields.redirectUri.trim(),
      acrValues: blankToUndefined(fields.acrValues),
      openId,
    },
    protect:
      kind === 'davinci'
        ? {
            envId: blankToUndefined(fields.protectEnvId),
          }
        : undefined,
  };
}

/**
 * Reads a config back into form values, for editing or duplicating.
 *
 * @param kind Configuration kind.
 * @param name Display name.
 * @param config Source config.
 * @returns Form values.
 */
export function toFields(
  kind: ConfigKind,
  name: string,
  config: UnifiedConfig,
): ConfigFields {
  const { journey, oidc, protect } = config;
  return {
    name,
    serverUrl: journey?.serverUrl ?? '',
    realm: journey?.realm ?? '',
    cookie: journey?.cookie ?? '',
    clientId: oidc?.clientId ?? '',
    discoveryEndpoint: oidc?.discoveryEndpoint ?? '',
    scopes: oidc?.scopes.join(',') ?? '',
    redirectUri: kind === 'deviceAuth' ? '' : (oidc?.redirectUri ?? ''),
    acrValues: oidc?.acrValues ?? '',
    protectEnvId: protect?.envId ?? '',
    ...Object.fromEntries(
      ENDPOINT_KEYS.map(key => [key, oidc?.openId?.[key] ?? '']),
    ),
  };
}

/**
 * Checks required fields and that the result is a valid unified config.
 *
 * @param kind Configuration kind.
 * @param fields Form values.
 * @returns An error message, or `null` when the form can be saved.
 */
export function validateFields(
  kind: ConfigKind,
  fields: ConfigFields,
): string | null {
  const missing = CONFIG_FIELDS[kind].find(
    field => field.required && !fields[field.key]?.trim(),
  );
  if (missing) {
    return `${missing.label} is required.`;
  }
  const result = parseUnifiedConfig(toUnifiedConfig(kind, fields));
  return result.ok ? null : `${result.error.field} ${result.error.reason}`;
}

/**
 * Converts a stored custom entry into a preset.
 *
 * @param entry Stored entry.
 * @returns The preset.
 */
export function customPreset(entry: CustomConfigEntry): ConfigPreset {
  return {
    id: entry.id,
    name: entry.fields.name,
    source: 'custom',
    config: toUnifiedConfig(entry.kind, entry.fields),
    kinds: [entry.kind],
  };
}

/**
 * Creates a unique id for a new custom entry.
 *
 * @returns Alphanumeric id, safe inside storage names.
 */
export function newCustomConfigId(): string {
  return `${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
}
