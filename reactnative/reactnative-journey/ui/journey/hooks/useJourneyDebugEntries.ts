/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useState } from 'react';
import {
  createJourneyDebugEntry,
  sanitizeDebugPayload,
  type JourneyDebugEntry,
} from '../utils/debug';

/**
 * Debug entry controller for Journey sample screens.
 *
 * @returns Debug entries plus append/clear actions.
 */
export function useJourneyDebugEntries(): {
  /**
   * Reverse-chronological debug entries (newest first).
   */
  debugEntries: JourneyDebugEntry[];
  /**
   * Appends one debug entry to the in-memory log.
   *
   * @param title - Entry title.
   * @param payload - Optional debug payload.
   * @returns Void.
   */
  appendDebug: (title: string, payload?: unknown) => void;
  /**
   * Removes all debug entries from in-memory state.
   *
   * @returns Void.
   */
  clearDebugEntries: () => void;
} {
  const [debugEntries, setDebugEntries] = useState<JourneyDebugEntry[]>([]);

  const appendDebug = useCallback((title: string, payload?: unknown): void => {
    const entry = createJourneyDebugEntry(
      title,
      payload === undefined ? undefined : sanitizeDebugPayload(payload),
    );
    // Keep newest entries first and cap in-memory history for UI responsiveness.
    setDebugEntries(previous => [entry, ...previous].slice(0, 50));
  }, []);

  const clearDebugEntries = useCallback((): void => {
    setDebugEntries([]);
  }, []);

  return {
    debugEntries,
    appendDebug,
    clearDebugEntries,
  };
}
