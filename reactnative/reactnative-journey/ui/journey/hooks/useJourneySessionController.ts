/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useEffect, useRef, useState } from 'react';
import { Alert } from 'react-native';
import { JourneyError } from '@ping-identity/rn-journey';
import type {
  JourneyNodeType,
  JourneyUserSession,
} from '@ping-identity/rn-journey';

/**
 * Configuration contract for `useJourneySessionController`.
 */
export type UseJourneySessionControllerOptions = {
  /**
   * Resolver for active Journey user session.
   */
  user: () => Promise<JourneyUserSession | null>;
  /**
   * Active node type.
   */
  nodeType?: JourneyNodeType;
  /**
   * Optional callback invoked once an authenticated state is detected.
   */
  onAuthenticated?: () => void;
  /**
   * When true, waits for explicit success-screen continue action before invoking `onAuthenticated`.
   */
  requireSuccessConfirmation?: boolean;
};

/**
 * Session/bootstrap/auth-notification state manager for Journey sample flows.
 *
 * @param options - Session controller options.
 * @returns Session state plus explicit success-notification action.
 */
export function useJourneySessionController(
  options: UseJourneySessionControllerOptions,
): {
  /**
   * True when a session is confirmed active for the current Journey client.
   */
  hasActiveSession: boolean;
  /**
   * Session-active state updater.
   *
   * @param value - Next active-session state.
   * @returns Void.
   */
  setHasActiveSession: (value: boolean) => void;
  /**
   * True while initial session bootstrap check is in progress.
   */
  isSessionCheckRunning: boolean;
  /**
   * Explicit success continuation callback used when confirmation is required.
   *
   * @returns Void.
   */
  onContinueAfterSuccess: () => void;
} {
  const {
    user,
    nodeType,
    onAuthenticated,
    requireSuccessConfirmation = false,
  } = options;

  const [hasActiveSession, setHasActiveSession] = useState<boolean>(false);
  const [isSessionCheckRunning, setIsSessionCheckRunning] =
    useState<boolean>(true);
  // Ensures authenticated callback is emitted once per authenticated state transition.
  const hasNotifiedAuthenticatedRef = useRef<boolean>(false);
  // Keeps callback identity stable inside async refresh logic.
  const userRef = useRef(user);
  userRef.current = user;

  const refreshSession = useCallback(
    async (showError = true): Promise<void> => {
      try {
        const session = await userRef.current();
        setHasActiveSession(Boolean(session));
      } catch (cause) {
        setHasActiveSession(false);
        if (showError) {
          Alert.alert(
            'Session refresh failed',
            cause instanceof JourneyError
              ? `[${cause.code}] ${cause.message}`
              : String(cause),
          );
        }
      }
    },
    [],
  );

  const onContinueAfterSuccess = useCallback((): void => {
    if (!onAuthenticated) {
      return;
    }
    hasNotifiedAuthenticatedRef.current = true;
    onAuthenticated();
  }, [onAuthenticated]);

  useEffect(() => {
    let cancelled = false;

    const loadSession = async (): Promise<void> => {
      setIsSessionCheckRunning(true);
      try {
        await refreshSession(false);
      } finally {
        if (!cancelled) {
          setIsSessionCheckRunning(false);
        }
      }
    };

    void loadSession();

    return () => {
      // Prevent post-unmount state writes from async bootstrap.
      cancelled = true;
    };
  }, [refreshSession]);

  useEffect(() => {
    if (nodeType === 'SuccessNode') {
      setHasActiveSession(true);
    }
  }, [nodeType]);

  useEffect(() => {
    if (!onAuthenticated) {
      return;
    }
    if (requireSuccessConfirmation) {
      hasNotifiedAuthenticatedRef.current = false;
      return;
    }

    const isAuthenticated = nodeType === 'SuccessNode' || hasActiveSession;
    if (!isAuthenticated) {
      hasNotifiedAuthenticatedRef.current = false;
      return;
    }

    if (hasNotifiedAuthenticatedRef.current) {
      return;
    }

    hasNotifiedAuthenticatedRef.current = true;
    onAuthenticated();
  }, [hasActiveSession, nodeType, onAuthenticated, requireSuccessConfirmation]);

  return {
    hasActiveSession,
    setHasActiveSession,
    isSessionCheckRunning,
    onContinueAfterSuccess,
  };
}
