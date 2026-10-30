/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCallback, useEffect, useState } from 'react';

/**
 * Selected profile key persisted across app launches.
 */
export type StoredSelection = {
  key: string | null;
  select: (key: string) => void;
  restored: boolean;
};

/**
 * Persists a selected profile key in AsyncStorage and restores it on start.
 *
 * @param storageKey AsyncStorage key holding the selection.
 * @returns The current key, a setter that also persists, and whether the
 * stored value has finished loading.
 */
export function useStoredSelection(storageKey: string): StoredSelection {
  const [key, setKey] = useState<string | null>(null);
  const [restored, setRestored] = useState(false);

  useEffect(() => {
    let active = true;
    AsyncStorage.getItem(storageKey)
      .then(stored => {
        if (active) {
          setKey(stored);
        }
      })
      .catch((error: unknown) => {
        console.warn(`Failed to restore '${storageKey}' selection`, error);
      })
      .finally(() => {
        if (active) {
          setRestored(true);
        }
      });
    return () => {
      active = false;
    };
  }, [storageKey]);

  const select = useCallback(
    (nextKey: string) => {
      setKey(nextKey);
      AsyncStorage.setItem(storageKey, nextKey).catch((error: unknown) => {
        console.warn(`Failed to persist '${storageKey}' selection`, error);
      });
    },
    [storageKey],
  );

  return { key, select, restored };
}
