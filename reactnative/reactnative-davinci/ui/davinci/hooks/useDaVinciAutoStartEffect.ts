/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useEffect, useRef } from 'react';
import { useFocusEffect } from '@react-navigation/native';
import type { DaVinciNode } from '@ping-identity/rn-davinci';

/**
 * Configuration contract for `useDaVinciAutoStartEffect`.
 */
export type UseDaVinciAutoStartEffectOptions = {
  /** Current loading state. */
  loading: boolean;
  /** Session bootstrap running state. */
  isSessionCheckRunning: boolean;
  /** Current authenticated session state. */
  hasActiveSession: boolean;
  /** Active DaVinci node. */
  node: DaVinciNode | null;
  /** Start action returning a success indicator. */
  onStart: () => Promise<boolean>;
};

/**
 * Auto-starts the DaVinci flow once when no node and no active session are
 * present, mirroring the Journey panel auto-start gating.
 *
 * @param options - Auto-start effect options.
 */
export function useDaVinciAutoStartEffect(
  options: UseDaVinciAutoStartEffectOptions,
): void {
  const { loading, isSessionCheckRunning, hasActiveSession, node, onStart } =
    options;
  const hasAutoStartedRef = useRef<boolean>(false);
  // Keep a ref so useFocusEffect can read the current node type without
  // listing it as a dependency — prevents the callback from firing when the
  // node changes while the screen is already focused (which would auto-clear
  // error/failure screens before the user reads them).
  const nodeTypeRef = useRef(node?.type);
  useEffect(() => {
    nodeTypeRef.current = node?.type;
  });

  // When the screen re-focuses after a terminal node (e.g. user navigated
  // away and came back), restart the flow for a fresh login form.
  useFocusEffect(
    useCallback(() => {
      const currentType = nodeTypeRef.current;
      if (
        currentType === 'SuccessNode' ||
        currentType === 'ErrorNode' ||
        currentType === 'FailureNode'
      ) {
        hasAutoStartedRef.current = true;
        void onStart();
      }
    }, [onStart]),
  );

  useEffect(() => {
    if (hasAutoStartedRef.current) return;
    if (node) return;
    if (loading || isSessionCheckRunning || hasActiveSession) return;

    hasAutoStartedRef.current = true;
    void (async () => {
      try {
        const didStart = await onStart();
        if (!didStart) {
          hasAutoStartedRef.current = false;
        }
      } catch (error) {
        hasAutoStartedRef.current = false;
        console.error('[useDaVinciAutoStartEffect] onStart failed:', error);
      }
    })();
  }, [hasActiveSession, isSessionCheckRunning, loading, node, onStart]);
}
