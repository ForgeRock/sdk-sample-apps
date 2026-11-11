/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { LogLevel } from '@ping-identity/rn-logger';
import type {
  OidcCoreConfig,
  OidcOpenIdConfiguration,
} from '@ping-identity/rn-types';

/**
 * Log levels accepted by the unified configuration `log` field.
 */
export type UnifiedLogLevel = 'NONE' | 'WARN' | 'DEBUG';

/**
 * Journey section of the unified configuration, mapped onto the React Native
 * Journey client config (`cookieName` becomes `cookie`).
 */
export type UnifiedJourneyConfig = {
  serverUrl: string;
  realm?: string;
  cookie?: string;
};

/**
 * OIDC section of the unified configuration, mapped onto the React Native
 * OIDC config (`openId.userInfoEndpoint` is also accepted for `userinfoEndpoint`).
 */
export type UnifiedOidcConfig = OidcCoreConfig & {
  discoveryEndpoint: string;
};

/**
 * Protect section of the unified configuration, passed to Protect
 * initialization when a DaVinci configuration is first selected.
 */
export type UnifiedProtectConfig = {
  /** PingOne environment ID for the Protect SDK. */
  envId?: string;
};

/**
 * Parsed unified SDK configuration.
 */
export type UnifiedConfig = {
  timeout?: number;
  log?: UnifiedLogLevel;
  journey?: UnifiedJourneyConfig;
  oidc?: UnifiedOidcConfig;
  protect?: UnifiedProtectConfig;
};

/**
 * Field-level parse failure naming the offending JSON path.
 */
export type UnifiedConfigError = {
  field: string;
  reason: string;
};

/**
 * Result of {@link parseUnifiedConfig}.
 *
 * `warnings` lists valid-but-unsupported keys that were skipped.
 */
export type UnifiedConfigParseResult =
  | { ok: true; config: UnifiedConfig; warnings: string[] }
  | { ok: false; error: UnifiedConfigError };

type JsonObject = Record<string, unknown>;

class ConfigFieldError extends Error {
  constructor(
    readonly field: string,
    readonly reason: string,
  ) {
    super(`${field}: ${reason}`);
  }
}

const LOG_LEVELS: readonly UnifiedLogLevel[] = ['NONE', 'WARN', 'DEBUG'];

const isObject = (value: unknown): value is JsonObject =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

const joinPath = (parent: string, key: string): string =>
  parent ? `${parent}.${key}` : key;

function optionalObject(
  parent: JsonObject,
  key: string,
  parentPath: string,
): JsonObject | undefined {
  const value = parent[key];
  if (value === undefined) {
    return undefined;
  }
  if (!isObject(value)) {
    throw new ConfigFieldError(joinPath(parentPath, key), 'must be an object');
  }
  return value;
}

function optionalString(
  parent: JsonObject,
  key: string,
  parentPath: string,
): string | undefined {
  const value = parent[key];
  if (value === undefined) {
    return undefined;
  }
  if (typeof value !== 'string') {
    throw new ConfigFieldError(joinPath(parentPath, key), 'must be a string');
  }
  return value;
}

function requiredString(
  parent: JsonObject,
  key: string,
  parentPath: string,
): string {
  const value = optionalString(parent, key, parentPath);
  if (value === undefined) {
    throw new ConfigFieldError(joinPath(parentPath, key), 'is required');
  }
  if (value.trim() === '') {
    throw new ConfigFieldError(joinPath(parentPath, key), 'must not be empty');
  }
  return value;
}

function optionalNumber(
  parent: JsonObject,
  key: string,
  parentPath: string,
): number | undefined {
  const value = parent[key];
  if (value === undefined) {
    return undefined;
  }
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new ConfigFieldError(joinPath(parentPath, key), 'must be a number');
  }
  return value;
}

function optionalBoolean(
  parent: JsonObject,
  key: string,
  parentPath: string,
): boolean | undefined {
  const value = parent[key];
  if (value === undefined) {
    return undefined;
  }
  if (typeof value !== 'boolean') {
    throw new ConfigFieldError(joinPath(parentPath, key), 'must be a boolean');
  }
  return value;
}

function requiredStringArray(
  parent: JsonObject,
  key: string,
  parentPath: string,
): string[] {
  const path = joinPath(parentPath, key);
  const value = parent[key];
  if (value === undefined) {
    throw new ConfigFieldError(path, 'is required');
  }
  if (!Array.isArray(value)) {
    throw new ConfigFieldError(path, 'must be an array of strings');
  }
  return value.map((item, index) => {
    if (typeof item !== 'string') {
      throw new ConfigFieldError(`${path}[${index}]`, 'must be a string');
    }
    return item;
  });
}

function optionalStringMap(
  parent: JsonObject,
  key: string,
  parentPath: string,
): Record<string, string> | undefined {
  const map = optionalObject(parent, key, parentPath);
  if (!map) {
    return undefined;
  }
  const path = joinPath(parentPath, key);
  return Object.fromEntries(
    Object.entries(map).map(([entryKey, entryValue]) => {
      if (typeof entryValue !== 'string') {
        throw new ConfigFieldError(`${path}.${entryKey}`, 'must be a string');
      }
      return [entryKey, entryValue];
    }),
  );
}

function parseOpenId(
  oidc: JsonObject,
  parentPath: string,
): OidcOpenIdConfiguration | undefined {
  const openId = optionalObject(oidc, 'openId', parentPath);
  if (!openId) {
    return undefined;
  }
  const path = joinPath(parentPath, 'openId');
  return {
    authorizationEndpoint: optionalString(
      openId,
      'authorizationEndpoint',
      path,
    ),
    tokenEndpoint: optionalString(openId, 'tokenEndpoint', path),
    userinfoEndpoint:
      optionalString(openId, 'userinfoEndpoint', path) ??
      optionalString(openId, 'userInfoEndpoint', path),
    endSessionEndpoint: optionalString(openId, 'endSessionEndpoint', path),
    revocationEndpoint: optionalString(openId, 'revocationEndpoint', path),
    deviceAuthorizationEndpoint: optionalString(
      openId,
      'deviceAuthorizationEndpoint',
      path,
    ),
  };
}

function parseOidc(
  root: JsonObject,
  warnings: string[],
): UnifiedOidcConfig | undefined {
  const oidc = optionalObject(root, 'oidc', '');
  if (!oidc) {
    return undefined;
  }
  if (oidc.authorizationDetails !== undefined) {
    warnings.push(
      'oidc.authorizationDetails is not supported by the React Native SDK and was ignored',
    );
  }
  return {
    clientId: requiredString(oidc, 'clientId', 'oidc'),
    discoveryEndpoint: requiredString(oidc, 'discoveryEndpoint', 'oidc'),
    scopes: requiredStringArray(oidc, 'scopes', 'oidc'),
    redirectUri: requiredString(oidc, 'redirectUri', 'oidc'),
    signOutRedirectUri: optionalString(oidc, 'signOutRedirectUri', 'oidc'),
    refreshThreshold: optionalNumber(oidc, 'refreshThreshold', 'oidc'),
    loginHint: optionalString(oidc, 'loginHint', 'oidc'),
    state: optionalString(oidc, 'state', 'oidc'),
    nonce: optionalString(oidc, 'nonce', 'oidc'),
    display: optionalString(oidc, 'display', 'oidc'),
    prompt: optionalString(oidc, 'prompt', 'oidc'),
    uiLocales: optionalString(oidc, 'uiLocales', 'oidc'),
    acrValues: optionalString(oidc, 'acrValues', 'oidc'),
    par: optionalBoolean(oidc, 'par', 'oidc'),
    additionalParameters: optionalStringMap(
      oidc,
      'additionalParameters',
      'oidc',
    ),
    openId: parseOpenId(oidc, 'oidc'),
  };
}

function parseJourney(root: JsonObject): UnifiedJourneyConfig | undefined {
  const journey = optionalObject(root, 'journey', '');
  if (!journey) {
    return undefined;
  }
  return {
    serverUrl: requiredString(journey, 'serverUrl', 'journey'),
    realm: optionalString(journey, 'realm', 'journey'),
    cookie: optionalString(journey, 'cookieName', 'journey'),
  };
}

function parseProtect(root: JsonObject): UnifiedProtectConfig | undefined {
  const protect = optionalObject(root, 'protect', '');
  if (!protect) {
    return undefined;
  }
  return {
    envId: optionalString(protect, 'envId', 'protect'),
  };
}

function parseLog(root: JsonObject): UnifiedLogLevel | undefined {
  const value = optionalString(root, 'log', '');
  if (value === undefined) {
    return undefined;
  }
  if (!LOG_LEVELS.includes(value as UnifiedLogLevel)) {
    throw new ConfigFieldError(
      'log',
      `must be one of ${LOG_LEVELS.join(', ')}`,
    );
  }
  return value as UnifiedLogLevel;
}

/**
 * Parses and validates one unified SDK configuration document.
 *
 * Required keys are `oidc.clientId`, `oidc.discoveryEndpoint`, `oidc.scopes`
 * and `oidc.redirectUri` when `oidc` is present, and `journey.serverUrl` when
 * `journey` is present. A document needs `journey` or `oidc`. Unknown keys are
 * ignored; a wrong type is reported with the offending field path.
 *
 * @param json Parsed JSON value of the file.
 * @returns The mapped config, or the first field error found.
 */
export function parseUnifiedConfig(json: unknown): UnifiedConfigParseResult {
  try {
    if (!isObject(json)) {
      throw new ConfigFieldError('(root)', 'must be a JSON object');
    }
    const warnings: string[] = [];
    const config: UnifiedConfig = {
      timeout: optionalNumber(json, 'timeout', ''),
      log: parseLog(json),
      journey: parseJourney(json),
      oidc: parseOidc(json, warnings),
      protect: parseProtect(json),
    };
    if (!config.journey && !config.oidc) {
      throw new ConfigFieldError('oidc', 'is required when journey is absent');
    }
    return { ok: true, config, warnings };
  } catch (error) {
    if (error instanceof ConfigFieldError) {
      return { ok: false, error: { field: error.field, reason: error.reason } };
    }
    throw error;
  }
}

/**
 * Maps the unified `log` value onto the rn-logger level.
 *
 * @param log Unified log level, when configured.
 * @returns Matching rn-logger level, or `undefined` when not configured.
 */
export function toLogLevel(
  log: UnifiedLogLevel | undefined,
): LogLevel | undefined {
  switch (log) {
    case 'NONE':
      return 'none';
    case 'WARN':
      return 'warn';
    case 'DEBUG':
      return 'debug';
    default:
      return undefined;
  }
}
