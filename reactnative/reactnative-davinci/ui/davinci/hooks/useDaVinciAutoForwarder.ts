/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useRef } from 'react';
import type {
  DaVinciFormResult,
  DaVinciNextInput,
  DaVinciNode,
} from '@ping-identity/rn-davinci';

/**
 * Options accepted by `useDaVinciAutoForwarder`.
 */
export type UseDaVinciAutoForwarderOptions = {
  /**
   * Active DaVinci node.
   */
  node: DaVinciNode | null;
  /**
   * Headless form state for the active node.
   */
  form: DaVinciFormResult;
  /**
   * True while a DaVinci action is in flight.
   */
  loading: boolean;
  /**
   * Stable key derived from the active node — used to deduplicate
   * auto-submits so the same node is never forwarded twice.
   */
  continueNodeKey: string;
  /**
   * True only in the window immediately after `authorizeForDaVinci` completes.
   * Prevents the forwarder from firing on the initial flow node.
   */
  enabled: boolean;
  /**
   * Called after the forwarder fires so the controller can clear the enabled flag.
   */
  onForwarded: () => void;
  /**
   * DaVinci `next` action.
   */
  next: (input: DaVinciNextInput) => Promise<unknown>;
};

/**
 * Auto-forwards a DaVinci `ContinueNode` that requires no manual user input,
 * but only when `enabled` is true (i.e. immediately after an IdP authorize).
 *
 * @remarks
 * Mirrors the Android sample app's post-IdP-authorize behavior: after
 * `authorizeForDaVinci` + `next()` the server returns an intermediate
 * `ContinueNode` containing only a `SUBMIT_BUTTON`. This hook detects that
 * state and calls `next(input)` automatically so the user never sees a
 * "Continue" button they did not need to tap.
 *
 * The `enabled` gate ensures this never fires on the initial `start()` node.
 *
 * @param options - Auto-forwarder options.
 */
export function useDaVinciAutoForwarder(
  options: UseDaVinciAutoForwarderOptions,
): void {
  const { node, form, loading, continueNodeKey, enabled, onForwarded, next } =
    options;
  const lastNodeKeyRef = useRef<string | null>(null);

  useEffect(() => {
    if (node?.type !== 'ContinueNode') {
      lastNodeKeyRef.current = null;
      return;
    }
    if (!enabled) return;
    if (loading) return;
    if (!continueNodeKey) return;
    if (lastNodeKeyRef.current === continueNodeKey) return;

    const { meta, canSubmit, input } = form;
    if (meta.hasManual) return;
    if (meta.hasIntegrationRequired) return;
    if (meta.hasUnsupported) return;
    if (!canSubmit) return;

    lastNodeKeyRef.current = continueNodeKey;
    onForwarded();
    void next(input).catch(() => {
      // Error state is surfaced by the useDaVinci hook.
    });
  }, [continueNodeKey, enabled, form, loading, next, node?.type, onForwarded]);
}
