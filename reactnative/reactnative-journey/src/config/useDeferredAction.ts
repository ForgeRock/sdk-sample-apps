/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useRef } from 'react';

/**
 * Holds one action to run once a navigation transition has settled.
 */
export type DeferredAction = {
  /** Replaces any pending action with `action`. */
  schedule: (action: () => void) => void;
  /** Runs and clears the pending action, if any. */
  flush: () => void;
};

/**
 * Lets a screen that is about to be popped hand work to a screen that outlives
 * the pop.
 *
 * @returns Stable `schedule` and `flush` functions.
 */
export function useDeferredAction(): DeferredAction {
  const pending = useRef<(() => void) | null>(null);

  const schedule = useCallback((action: () => void) => {
    pending.current = action;
  }, []);

  const flush = useCallback(() => {
    const action = pending.current;
    pending.current = null;
    action?.();
  }, []);

  return { schedule, flush };
}
