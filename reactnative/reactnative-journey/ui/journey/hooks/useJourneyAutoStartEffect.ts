/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useRef } from 'react';
import type { JourneyNode } from '@ping-identity/rn-journey';

/**
 * Configuration contract for `useJourneyAutoStartEffect`.
 */
export type UseJourneyAutoStartEffectOptions = {
  /**
   * Enables or disables auto-start behavior.
   */
  autoStartOnMount: boolean;
  /**
   * Current loading state.
   */
  loading: boolean;
  /**
   * Session bootstrap running state.
   */
  isSessionCheckRunning: boolean;
  /**
   * Current authenticated session state.
   */
  hasActiveSession: boolean;
  /**
   * Active Journey node.
   */
  node: JourneyNode | null;
  /**
   * Current editable journey name value.
   */
  journeyName: string;
  /**
   * Start action returning success indicator.
   */
  onStart: () => Promise<boolean>;
  /**
   * Disposes any in-flight Journey session so the next start begins fresh.
   */
  dispose: () => Promise<void>;
};

/**
 * Runs sample-app auto-start behavior when configured and eligible.
 *
 * Disposes any stale Journey state (including mid-flow ContinueNodes from a
 * previous screen visit) before starting, so re-entering the panel always
 * produces a clean journey.
 *
 * @param options - Auto-start effect options.
 * @returns Void.
 */
export function useJourneyAutoStartEffect(
  options: UseJourneyAutoStartEffectOptions,
): void {
  const {
    autoStartOnMount,
    loading,
    isSessionCheckRunning,
    hasActiveSession,
    node,
    journeyName,
    onStart,
    dispose,
  } = options;
  const hasAutoStartedRef = useRef<boolean>(false);

  useEffect(() => {
    if (!autoStartOnMount) return;
    if (hasAutoStartedRef.current) return;
    if (loading || isSessionCheckRunning || hasActiveSession) return;
    if (!journeyName.trim()) return;

    hasAutoStartedRef.current = true;
    void (async () => {
      // Clear any stale journey state from a previous screen visit so
      // re-entering the panel after an error or abandoned mid-flow node
      // always produces a fresh session.
      if (node) {
        try {
          await dispose();
        } catch {
          // Best effort; continue with start regardless.
        }
      }
      const didStart = await onStart();
      if (!didStart) {
        hasAutoStartedRef.current = false;
      }
    })();
  }, [
    autoStartOnMount,
    dispose,
    hasActiveSession,
    isSessionCheckRunning,
    journeyName,
    loading,
    node,
    onStart,
  ]);
}
