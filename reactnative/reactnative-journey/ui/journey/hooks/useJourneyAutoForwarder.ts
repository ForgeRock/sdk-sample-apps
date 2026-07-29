/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useRef } from 'react';
import { formatError } from '../../utils/formatError';
import type {
  JourneyFormResult,
  JourneyNextInput,
  JourneyNode,
} from '@ping-identity/rn-journey';
import type { UseJourneyIntegrationRunnerResult } from './useJourneyIntegrationRunner';

/**
 * Options accepted by `useJourneyAutoForwarder`.
 */
export type UseJourneyAutoForwarderOptions = {
  /**
   * Active Journey node.
   */
  node: JourneyNode | null;
  /**
   * Headless form state for the active node.
   */
  form: JourneyFormResult;
  /**
   * True while a Journey action is currently in flight.
   */
  loading: boolean;
  /**
   * Stable signature derived from the current node's fields.
   */
  continueNodeKey: string;
  /**
   * Device profile callback presence used to bail out of auto-forwarding.
   */
  hasDeviceProfileCallback: boolean;
  /**
   * Polling wait callback presence used to bail out of auto-forwarding.
   */
  hasPollingWaitCallback: boolean;
  /**
   * Suspended callback presence used to bail out of auto-forwarding.
   */
  hasSuspendedCallback: boolean;
  /**
   * Integration runner helpers derived from `useJourneyIntegrationRunner`.
   */
  runner: UseJourneyIntegrationRunnerResult;
  /**
   * Journey `next(...)` action used to submit after integrations run.
   */
  next: (input: JourneyNextInput) => Promise<unknown>;
  /**
   * Debug logger appended to the sample app's debug panel.
   */
  appendDebug: (message: string, payload?: unknown) => void;
};

/**
 * Auto-forwards any Journey `ContinueNode` whose fields are fully handled by
 * auto-forwardable integrations and require no additional manual user input.
 *
 * @param options - Auto-forwarder options.
 */
export function useJourneyAutoForwarder(
  options: UseJourneyAutoForwarderOptions,
): void {
  const {
    node,
    form,
    loading,
    continueNodeKey,
    hasDeviceProfileCallback,
    hasPollingWaitCallback,
    hasSuspendedCallback,
    runner,
    next,
    appendDebug,
  } = options;

  const lastNodeKeyRef = useRef<string | null>(null);

  useEffect(() => {
    const isContinueNode = node?.type === 'ContinueNode';
    if (!isContinueNode) {
      lastNodeKeyRef.current = null;
      return;
    }
    if (loading) return;
    if (continueNodeKey.length === 0) return;
    if (lastNodeKeyRef.current === continueNodeKey) return;

    const hasManualInput = form.fields.some(field => field.requiresUserInput);
    if (hasManualInput) return;
    if (form.meta.hasUnsupported) return;
    if (hasDeviceProfileCallback) return;
    if (hasPollingWaitCallback) return;
    if (hasSuspendedCallback) return;
    if (runner.hasUnhandledIntegrationIssue(form)) return;
    if (!runner.hasHandledCallback(form)) return;
    if (!runner.canAutoForward(form)) return;

    lastNodeKeyRef.current = continueNodeKey;

    void (async () => {
      // Match the native sample pattern: on integration failure, the native
      // SDK has already set `clientError` on the callback payload. Submit
      // anyway so AM's journey tree routes to the configured failure edge.
      try {
        await runner.runIntegrations(form);
      } catch (error) {
        appendDebug('Integration failed; submitting to let server route', {
          error: formatError(error),
        });
      }

      try {
        const submit: JourneyNextInput = {
          callbacks: runner.filterCallbacksForSubmit(form.input.callbacks),
        };
        await next(submit);
      } catch (error) {
        // Journey hook error state will surface this; debug effect logs it.
        void error;
      }
    })();
  }, [
    appendDebug,
    continueNodeKey,
    form,
    hasDeviceProfileCallback,
    hasPollingWaitCallback,
    hasSuspendedCallback,
    loading,
    next,
    node,
    runner,
  ]);
}
