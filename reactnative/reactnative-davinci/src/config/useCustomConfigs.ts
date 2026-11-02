/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  customPreset,
  newCustomConfigId,
  validateFields,
  type ConfigFields,
  type ConfigKind,
  type ConfigPreset,
  type CustomConfigEntry,
} from './customConfigs';

const STORAGE_KEY = 'customConfigs';

const isEntry = (value: unknown): value is CustomConfigEntry => {
  const entry = value as CustomConfigEntry;
  return (
    typeof entry === 'object' &&
    entry !== null &&
    typeof entry.id === 'string' &&
    typeof entry.kind === 'string' &&
    typeof entry.fields === 'object' &&
    entry.fields !== null
  );
};

/**
 * Custom configurations persisted in AsyncStorage.
 */
export type CustomConfigs = {
  /** Presets of all custom entries; identity is stable while an entry is unchanged. */
  presets: readonly ConfigPreset[];
  restored: boolean;
  add: (kind: ConfigKind, fields: ConfigFields) => void;
  update: (id: string, fields: ConfigFields) => void;
  remove: (id: string) => void;
};

/**
 * Loads, validates and persists user-created configurations.
 *
 * @returns Custom presets and add/update/remove actions.
 */
export function useCustomConfigs(): CustomConfigs {
  const [entries, setEntries] = useState<readonly CustomConfigEntry[]>([]);
  const [restored, setRestored] = useState(false);
  const presetCache = useRef(new Map<string, ConfigPreset>());

  useEffect(() => {
    let active = true;
    AsyncStorage.getItem(STORAGE_KEY)
      .then(stored => {
        if (!active || !stored) {
          return;
        }
        const parsed: unknown = JSON.parse(stored);
        if (Array.isArray(parsed)) {
          setEntries(parsed.filter(isEntry));
        }
      })
      .catch((error: unknown) => {
        console.warn('Failed to restore custom configs', error);
      })
      .finally(() => {
        if (active) {
          setRestored(true);
        }
      });
    return () => {
      active = false;
    };
  }, []);

  const presets = useMemo(() => {
    const nextCache = new Map<string, ConfigPreset>();
    const result = entries.flatMap(entry => {
      const cacheKey = `${entry.id}\u0000${JSON.stringify(entry.fields)}`;
      const cached = presetCache.current.get(cacheKey);
      if (cached) {
        nextCache.set(cacheKey, cached);
        return [cached];
      }
      const error = validateFields(entry.kind, entry.fields);
      if (error) {
        console.warn(`Skipping custom config '${entry.id}': ${error}`);
        return [];
      }
      const preset = customPreset(entry);
      nextCache.set(cacheKey, preset);
      return [preset];
    });
    presetCache.current = nextCache;
    return result;
  }, [entries]);

  const persist = useCallback((next: readonly CustomConfigEntry[]) => {
    setEntries(next);
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next)).catch(
      (error: unknown) => {
        console.warn('Failed to persist custom configs', error);
      },
    );
  }, []);

  const add = useCallback(
    (kind: ConfigKind, fields: ConfigFields) =>
      persist([...entries, { id: newCustomConfigId(), kind, fields }]),
    [entries, persist],
  );

  const update = useCallback(
    (id: string, fields: ConfigFields) =>
      persist(
        entries.map(entry => (entry.id === id ? { ...entry, fields } : entry)),
      ),
    [entries, persist],
  );

  const remove = useCallback(
    (id: string) => persist(entries.filter(entry => entry.id !== id)),
    [entries, persist],
  );

  return { presets, restored, add, update, remove };
}
