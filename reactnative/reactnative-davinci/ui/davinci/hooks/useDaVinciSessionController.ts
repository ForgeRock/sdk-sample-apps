/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { useFocusEffect } from '@react-navigation/native';
import type { DaVinciUserSession } from '@ping-identity/rn-davinci';

/**
 * Configuration contract for `useDaVinciSessionController`.
 */
export type UseDaVinciSessionControllerOptions = {
  /**
   * Resolver for the active DaVinci user session.
   */
  user: () => Promise<DaVinciUserSession | null>;
  /**
   * Active node type (e.g. `'SuccessNode'`).
   *
   * @remarks
   * When the flow reaches `SuccessNode` the session is marked active without
   * waiting for a fresh `user()` round-trip.
   */
  nodeType?: 'ContinueNode' | 'SuccessNode' | 'ErrorNode' | 'FailureNode';
};

/**
 * Session/bootstrap state manager for the DaVinci sample screen.
 *
 * @remarks
 * Re-resolves the session every time the screen gains focus so that a revoke
 * or logout triggered from another screen (e.g. `TokenScreen`) is reflected on
 * return instead of showing a stale authenticated card.
 *
 * @param options - Session controller options.
 * @returns Session state plus a manual setter for downstream actions.
 */
export function useDaVinciSessionController(
  options: UseDaVinciSessionControllerOptions,
): {
  /** True when a session is confirmed active for the current DaVinci client. */
  hasActiveSession: boolean;
  /**
   * Manually update the active-session state (used by logout/revoke flows).
   *
   * @param value - Next active-session state.
   */
  setHasActiveSession: (value: boolean) => void;
  /** True while the initial session bootstrap check is in progress. */
  isSessionCheckRunning: boolean;
} {
  const { user, nodeType } = options;

  const [hasActiveSession, setHasActiveSession] = useState<boolean>(false);
  const [isSessionCheckRunning, setIsSessionCheckRunning] =
    useState<boolean>(true);

  const userRef = useRef(user);
  userRef.current = user;

  useFocusEffect(
    useCallback(() => {
      let cancelled = false;

      const checkSession = async (): Promise<void> => {
        setIsSessionCheckRunning(true);
        try {
          const session = await userRef.current();
          if (!cancelled) {
            setHasActiveSession(Boolean(session));
          }
        } catch {
          if (!cancelled) {
            setHasActiveSession(false);
          }
        } finally {
          if (!cancelled) {
            setIsSessionCheckRunning(false);
          }
        }
      };

      void checkSession();

      return () => {
        cancelled = true;
      };
    }, []),
  );

  useEffect(() => {
    if (nodeType === 'SuccessNode') {
      setHasActiveSession(true);
    }
  }, [nodeType]);

  return {
    hasActiveSession,
    setHasActiveSession,
    isSessionCheckRunning,
  };
}
