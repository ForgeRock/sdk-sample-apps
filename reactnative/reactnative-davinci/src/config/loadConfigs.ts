/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { parseUnifiedConfig, type UnifiedConfig } from './unifiedConfig';

/**
 * A bundled unified configuration file, named after its file.
 */
export type JsonConfigPreset = {
  name: string;
  config: UnifiedConfig;
};

/**
 * Receiver for skipped-file diagnostics.
 */
export type ConfigWarn = (message: string) => void;

const configFiles = require.context('../../assets/configs', false, /\.json$/);

const presetNameFrom = (key: string): string =>
  key.replace(/^\.\//, '').replace(/\.json$/, '');

/**
 * Loads every `assets/configs/*.json` file bundled by Metro.
 *
 * The file name without extension is the preset name. A file that fails
 * validation is skipped and reported through `warn` with the file and field.
 *
 * @param warn Receiver for skipped-file and unsupported-key diagnostics.
 * @returns Valid presets sorted by name.
 */
export function loadJsonConfigPresets(warn: ConfigWarn): JsonConfigPreset[] {
  return configFiles
    .keys()
    .map(key => ({ key, name: presetNameFrom(key) }))
    .sort((a, b) => a.name.localeCompare(b.name))
    .flatMap(({ key, name }) => {
      const result = parseUnifiedConfig(configFiles(key));
      if (!result.ok) {
        warn(
          `Skipping config '${name}.json': ${result.error.field} ${result.error.reason}`,
        );
        return [];
      }
      result.warnings.forEach(message =>
        warn(`Config '${name}.json': ${message}`),
      );
      return [{ name, config: result.config }];
    });
}
