/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useMemo } from 'react';
import type {
  JourneyCallbackInput,
  JourneyCallbackType,
  JourneyClient,
  JourneyFormResult,
  JourneyNormalizedField,
} from '@ping-identity/rn-journey';
import type { JourneyIntegration } from '../integrations/types';

/**
 * Options accepted by the Journey integration runner hook.
 */
export type UseJourneyIntegrationRunnerOptions = {
  /**
   * Active Journey client used for callback resolution.
   */
  journeyClient: JourneyClient;
  /**
   * Registered integrations responsible for integration-required callbacks.
   */
  integrations: readonly JourneyIntegration[];
  /**
   * Debug logger appended to the sample app's debug panel.
   */
  appendDebug: (message: string, payload?: unknown) => void;
};

/**
 * Outcome aggregated across all integrations executed for a node.
 */
export type JourneyIntegrationRunSummary = {
  /**
   * True when at least one integration reported a non-fatal cancellation.
   */
  cancelled: boolean;
};

/**
 * Shared utilities exposed by the Journey integration runner hook.
 */
export type UseJourneyIntegrationRunnerResult = {
  /**
   * Callback types handled by any registered integration.
   */
  handledCallbackTypes: ReadonlySet<JourneyCallbackType>;
  /**
   * Returns true when the form contains at least one integration-handled
   * callback.
   */
  hasHandledCallback: (form: JourneyFormResult) => boolean;
  /**
   * Executes every integration-required field in the form using the matching
   * integration.
   */
  runIntegrations: (
    form: JourneyFormResult,
  ) => Promise<JourneyIntegrationRunSummary>;
  /**
   * Filters native-handled and hidden callbacks out of a submit payload.
   */
  filterCallbacksForSubmit: (
    callbacks: readonly JourneyCallbackInput[] | undefined,
  ) => JourneyCallbackInput[];
  /**
   * True when every field in the form is either non-integration or handled by
   * an auto-forwardable integration path. Consumers combine this with manual-
   * input/unsupported checks before deciding to auto-forward.
   */
  canAutoForward: (form: JourneyFormResult) => boolean;
  /**
   * Returns true when any form issue identifies a callback that no registered
   * integration handles.
   */
  hasUnhandledIntegrationIssue: (form: JourneyFormResult) => boolean;
};

/**
 * Composes Journey integrations into reusable submit/auto-forward helpers.
 *
 * @param options - Runner wiring options.
 * @returns Runner helpers used by the panel controller.
 */
export function useJourneyIntegrationRunner(
  options: UseJourneyIntegrationRunnerOptions,
): UseJourneyIntegrationRunnerResult {
  const { journeyClient, integrations, appendDebug } = options;

  const handledCallbackTypes = useMemo<ReadonlySet<JourneyCallbackType>>(() => {
    const set = new Set<JourneyCallbackType>();
    for (const integration of integrations) {
      for (const type of integration.callbackTypes) {
        set.add(type);
      }
    }
    return set;
  }, [integrations]);

  const integrationByType = useMemo<
    ReadonlyMap<JourneyCallbackType, JourneyIntegration>
  >(() => {
    const map = new Map<JourneyCallbackType, JourneyIntegration>();
    for (const integration of integrations) {
      for (const type of integration.callbackTypes) {
        map.set(type, integration);
      }
    }
    return map;
  }, [integrations]);

  const runIntegrations = useCallback(
    async (form: JourneyFormResult): Promise<JourneyIntegrationRunSummary> => {
      let cancelled = false;
      const fields = form.fields.filter(
        (field: JourneyNormalizedField) =>
          field.executionMode === 'integration_required' &&
          handledCallbackTypes.has(field.ref.type),
      );
      for (const field of fields) {
        const integration = integrationByType.get(field.ref.type);
        if (!integration) continue;
        const result = await integration.run(field, journeyClient);
        if (result.cancelled) {
          cancelled = true;
          appendDebug(`Integration cancelled: ${integration.id}`, {
            callbackType: field.ref.type,
          });
        }
      }
      return { cancelled };
    },
    [appendDebug, handledCallbackTypes, integrationByType, journeyClient],
  );

  const filterCallbacksForSubmit = useCallback(
    (
      callbacks: readonly JourneyCallbackInput[] | undefined,
    ): JourneyCallbackInput[] =>
      (callbacks ?? []).filter(
        callback =>
          !handledCallbackTypes.has(callback.type) &&
          callback.type !== 'HiddenValueCallback',
      ),
    [handledCallbackTypes],
  );

  const canAutoForward = useCallback(
    (form: JourneyFormResult): boolean => {
      for (const field of form.fields) {
        if (field.executionMode !== 'integration_required') continue;
        const integration = integrationByType.get(field.ref.type);
        if (!integration) return false;
        if (!integration.canAutoForwardField(field)) return false;
      }
      return true;
    },
    [integrationByType],
  );

  const hasUnhandledIntegrationIssue = useCallback(
    (form: JourneyFormResult): boolean =>
      form.issues.some(
        issue =>
          issue.code === 'INTEGRATION_REQUIRED' &&
          (!issue.callbackType ||
            !handledCallbackTypes.has(issue.callbackType)),
      ),
    [handledCallbackTypes],
  );

  const hasHandledCallback = useCallback(
    (form: JourneyFormResult): boolean =>
      form.fields.some(field => handledCallbackTypes.has(field.ref.type)),
    [handledCallbackTypes],
  );

  return {
    handledCallbackTypes,
    hasHandledCallback,
    runIntegrations,
    filterCallbacksForSubmit,
    canAutoForward,
    hasUnhandledIntegrationIssue,
  };
}
