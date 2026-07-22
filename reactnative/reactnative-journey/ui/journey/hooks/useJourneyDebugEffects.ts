/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect } from 'react';
import type { JourneyError, JourneyNode } from '@ping-identity/rn-journey';

/**
 * Configuration contract for `useJourneyDebugEffects`.
 */
export type UseJourneyDebugEffectsOptions = {
  /**
   * Active Journey node.
   */
  node: JourneyNode | null;
  /**
   * Last Journey hook error.
   */
  error: JourneyError | null;
  /**
   * Debug append helper.
   */
  appendDebug: (title: string, payload?: unknown) => void;
};

/**
 * Emits node and error updates into the Journey debug log.
 *
 * @param options - Debug effect options.
 * @returns Void.
 */
export function useJourneyDebugEffects(
  options: UseJourneyDebugEffectsOptions,
): void {
  const { node, error, appendDebug } = options;

  useEffect(() => {
    if (!node?.type) {
      return;
    }
    appendDebug(`Node: ${node.type}`, node);
  }, [appendDebug, node]);

  useEffect(() => {
    if (!error) {
      return;
    }
    appendDebug('Journey hook error', error);
  }, [appendDebug, error]);
}
