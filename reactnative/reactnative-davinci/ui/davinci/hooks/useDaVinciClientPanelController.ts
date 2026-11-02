/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useMemo, useState } from 'react';
import {
  useDaVinci,
  useDaVinciContext,
  useDaVinciForm,
  type DaVinciError,
  type DaVinciFieldValidationError,
  type DaVinciFormResult,
  type DaVinciFormValue,
  type DaVinciNode,
  type PollingCollector,
  type PollingStatus,
} from '@ping-identity/rn-davinci';
import {
  createExternalIdpClient,
  socialLoginCollectorType,
  type IdpCollector,
} from '@ping-identity/rn-external-idp';
import {
  createFidoClient,
  fidoCollectorType,
  type FidoCollector,
} from '@ping-identity/rn-fido';
import {
  collectProtect,
  protectCollectorType,
} from '@ping-identity/rn-protect';
import { logger } from '@ping-identity/rn-logger';
import { useDaVinciSessionController } from './useDaVinciSessionController';
import { useDaVinciAutoStartEffect } from './useDaVinciAutoStartEffect';
import { useDaVinciAutoForwarder } from './useDaVinciAutoForwarder';

/**
 * Result contract consumed by `DaVinciClientPanel`.
 */
export type UseDaVinciClientPanelControllerResult = {
  /** Active DaVinci node. */
  node: DaVinciNode | null;
  /** Headless form state for the active continue node. */
  form: DaVinciFormResult;
  /** True while a DaVinci action is in flight. */
  loading: boolean;
  /** Last hook-level DaVinci error. */
  error: DaVinciError | null;
  /** Last IdP-authorize error message (cleared on next start). */
  idpError: string | null;
  /** Last FIDO ceremony error message (cleared on next start). */
  fidoError: string | null;
  /** Last Protect collect error message (cleared on next start). */
  protectError: string | null;
  /** True when a session is confirmed active for the current DaVinci client. */
  hasActiveSession: boolean;
  /** True while the initial session bootstrap check is running. */
  isSessionCheckRunning: boolean;
  /**
   * Submits the current form by calling `next` with the planned payload.
   */
  onSubmit: () => void;
  /**
   * Validates the current value for a collector.
   *
   * @param collectorKey Collector key to validate.
   * @param value Current rendered value for the collector.
   * @returns Validation errors for the collector.
   */
  onValidate: (
    collectorKey: string,
    value: DaVinciFormValue,
  ) => Promise<DaVinciFieldValidationError[]>;
  /**
   * Submits a flow collector (`SUBMIT_BUTTON`, `ACTION`, `FLOW_BUTTON`,
   * `FLOW_LINK`) by key.
   *
   * @remarks
   * Delegates to `form.setValue`, which auto-submits immediately for
   * `FlowCollector` keys — see {@link useDaVinciForm}'s `setValue` remarks.
   *
   * @param flowKey - Flow collector key.
   */
  onFlowAction: (flowKey: string) => void;
  /**
   * Launches the social login browser flow for an IDP collector, then
   * automatically advances the DaVinci flow via `next()`.
   *
   * @param collector - The IdpCollector to authorize.
   */
  onIdpAuthorize: (collector: IdpCollector) => Promise<void>;
  /**
   * Runs the native passkey ceremony for a FIDO collector, then advances the
   * DaVinci flow.
   *
   * @param collector - The FIDO collector to process.
   */
  onFidoCeremony: (collector: FidoCollector) => Promise<void>;
  /**
   * Streams {@link PollingStatus} updates for a {@link PollingCollector},
   * automatically advancing the flow via `next()` once a terminal status
   * (`complete`, `timedOut`, `expired`, `error`) is observed.
   *
   * @param collector - The PollingCollector to poll.
   * @param onStatus - Callback invoked with each streamed status tick.
   */
  onPollStatus: (
    collector: PollingCollector,
    onStatus: (status: PollingStatus) => void,
  ) => Promise<() => void>;
  /** Restarts the DaVinci flow. */
  onStart: () => Promise<void>;
  /** Logs out the active user and clears local session state. */
  onLogout: () => Promise<void>;
};

/**
 * Options for the DaVinci client panel controller hook.
 */
export type UseDaVinciClientPanelControllerOptions = {
  /**
   * Optional callback fired after the user dismisses a `SuccessNode` or logs
   * out from the panel.
   */
  onAuthenticated?: () => void;
  /**
   * Optional RFC 8628 `verification_uri_complete` used when this device is the
   * approving device in a device authorization grant. Passed to DaVinci
   * `start()` so the flow approves the requesting device.
   */
  verificationUri?: string;
  /**
   * Redirect URI of the selected DaVinci configuration, used to return from
   * external identity provider (social login) browser flows.
   */
  externalIdpRedirectUri?: string;
};

/**
 * Returns true when the supplied error represents a user-cancelled FIDO
 * authentication prompt.
 *
 * @param error Error returned by the FIDO client.
 * @returns Whether the error is the native authentication cancellation code.
 */
function isFidoAuthenticationCancelled(error: unknown): boolean {
  if (!error || typeof error !== 'object') {
    return false;
  }
  return (error as { code?: unknown }).code === 'FIDO_AUTHENTICATE_CANCELLED';
}

/**
 * Composes DaVinci sample panel behavior into a single controller hook.
 *
 * @remarks
 * - Checks for an active session on focus before auto-starting.
 * - Auto-starts the flow only when no node and no active session are present.
 * - Pairs `useDaVinci` (flow + session actions) with `useDaVinciForm` (form
 *   state for the active continue node) and exposes a flat panel contract.
 *
 * @param options - Optional controller options.
 * @returns Panel state and actions consumed by `DaVinciClientPanel`.
 */
export function useDaVinciClientPanelController(
  options: UseDaVinciClientPanelControllerOptions = {},
): UseDaVinciClientPanelControllerResult {
  const { onAuthenticated, verificationUri, externalIdpRedirectUri } = options;
  const davinciContext = useDaVinciContext();
  const {
    node,
    loading,
    error,
    start,
    next,
    validate,
    user,
    logoutUser,
    pollStatus,
  } = useDaVinci();
  const externalIdpLogger = useMemo(() => logger({ level: 'debug' }), []);
  const fidoLogger = useMemo(() => logger({ level: 'debug' }), []);
  const fido = useMemo(
    () => createFidoClient({ logger: fidoLogger }),
    [fidoLogger],
  );
  const externalIdp = useMemo(
    () =>
      createExternalIdpClient({
        redirectUri: externalIdpRedirectUri ?? '',
        logger: externalIdpLogger,
      }),
    [externalIdpLogger, externalIdpRedirectUri],
  );
  const form = useDaVinciForm(node, {
    handledCollectorTypes: new Set([
      socialLoginCollectorType,
      protectCollectorType,
      fidoCollectorType,
    ]),
  });

  const [idpError, setIdpError] = useState<string | null>(null);
  const [fidoError, setFidoError] = useState<string | null>(null);
  const [protectError, setProtectError] = useState<string | null>(null);
  const [idpJustAuthorized, setIdpJustAuthorized] = useState<boolean>(false);

  const { hasActiveSession, setHasActiveSession, isSessionCheckRunning } =
    useDaVinciSessionController({
      user,
      nodeType: node?.type,
    });

  const onStart = useCallback(async (): Promise<boolean> => {
    setIdpError(null);
    setFidoError(null);
    setProtectError(null);
    try {
      await start(verificationUri ? { verificationUri } : undefined);
      return true;
    } catch {
      // The hook captures and exposes the error via `error`.
      return false;
    }
  }, [start, verificationUri]);

  useDaVinciAutoStartEffect({
    loading,
    isSessionCheckRunning,
    hasActiveSession,
    node,
    onStart,
  });

  const continueNodeKey = useMemo(() => {
    if (node?.type !== 'ContinueNode') return '';
    return node.collectors.map(c => c.key ?? c.type).join(',');
  }, [node]);

  useDaVinciAutoForwarder({
    node,
    form,
    loading,
    continueNodeKey,
    enabled: idpJustAuthorized,
    onForwarded: () => setIdpJustAuthorized(false),
    next,
  });

  const onProtectCollect = useCallback(async (): Promise<void> => {
    const protectFields = form.fields.filter(
      f => f.type === protectCollectorType,
    );
    if (protectFields.length === 0) {
      return;
    }
    const davinciClient = davinciContext?.client;
    if (!davinciClient) {
      throw new Error('[DaVinci] collectProtect: no DaVinci client in context');
    }
    try {
      for (let i = 0; i < protectFields.length; i++) {
        await collectProtect(davinciClient);
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : String(err);
      setProtectError(msg);
      throw err;
    }
  }, [davinciContext?.client, form.fields]);

  const onSubmit = useCallback((): void => {
    if (loading) {
      return;
    }
    const plan = form.buildInput();
    if (!plan.canSubmit) {
      return;
    }
    onProtectCollect()
      .then(() => next(plan.input))
      .catch((err: unknown) => {
        const msg = err instanceof Error ? err.message : String(err);
        console.warn(`[DaVinci] onSubmit failed: ${msg}`);
      });
  }, [form, loading, next, onProtectCollect]);

  const onValidate = useCallback(
    (
      collectorKey: string,
      value: DaVinciFormValue,
    ): Promise<DaVinciFieldValidationError[]> => validate(collectorKey, value),
    [validate],
  );

  const onFidoCeremony = useCallback(
    async (collector: FidoCollector): Promise<void> => {
      if (loading) {
        return;
      }
      setFidoError(null);
      const davinciClient = davinciContext?.client;
      if (!davinciClient) {
        console.warn('[DaVinci] FIDO ceremony: no DaVinci client in context');
        return;
      }
      // Native resolvers index collectors per concrete ceremony class
      // (registration vs. authentication), so the index must be computed
      // within the ceremony-matched subset, not across all FIDO collectors.
      const fidoFields = form.fields.filter(
        f =>
          f.type === fidoCollectorType &&
          (f as unknown as FidoCollector).action === collector.action,
      );
      const index = fidoFields.findIndex(f => f.key === collector.key);
      const collectorIndex = index >= 0 ? index : 0;
      try {
        if (collector.action === 'REGISTER') {
          await fido.registerForDaVinci(davinciClient, {
            index: collectorIndex,
          });
        } else {
          await fido.authenticateForDaVinci(davinciClient, {
            index: collectorIndex,
          });
        }
        await next({ collectors: [] });
      } catch (fidoErrorValue) {
        if (isFidoAuthenticationCancelled(fidoErrorValue)) {
          setFidoError('Passkey authentication was canceled.');
          return;
        }
        console.warn('[DaVinci] FIDO ceremony failed:', fidoErrorValue);
        const msg =
          fidoErrorValue instanceof Error
            ? fidoErrorValue.message
            : String(fidoErrorValue);
        setFidoError(msg);
      }
    },
    [davinciContext?.client, fido, form.fields, loading, next],
  );

  const onIdpAuthorize = useCallback(
    async (collector: IdpCollector): Promise<void> => {
      if (loading) {
        return;
      }
      setIdpError(null);
      const davinciClient = davinciContext?.client;
      if (!davinciClient) {
        console.warn(
          '[DaVinci] authorizeForDaVinci: no DaVinci client in context',
        );
        return;
      }
      // Determine which index this collector occupies among IDP collectors on the
      // current node so the native side can resolve the right IdpCollector.
      const idpFields = form.fields.filter(
        f => f.type === socialLoginCollectorType,
      );
      const index = idpFields.findIndex(f => f.key === collector.key);
      try {
        // authorizeForDaVinci opens the IdP browser flow and sets the
        // resume request internally — token flows through the subsequent next().
        await externalIdp.authorizeForDaVinci(davinciClient, {
          index: index >= 0 ? index : 0,
        });
        setIdpJustAuthorized(true);
        await next({ collectors: [] });
      } catch (err) {
        console.warn('[DaVinci] authorizeForDaVinci failed:', err);
        const msg = err instanceof Error ? err.message : String(err);
        setIdpError(msg);
      }
    },
    [davinciContext?.client, externalIdp, form.fields, loading, next],
  );

  const onFlowAction = useCallback(
    (flowKey: string): void => {
      if (loading) {
        return;
      }
      // setValue on a FlowCollector key auto-submits via next() immediately
      // (see useDaVinciForm's setValue remarks) — exercises the same
      // auto-submit path a field's onChange would trigger.
      const pending = form.setValue(flowKey, flowKey);
      pending?.catch(() => {
        // `error` is already updated by the hook.
      });
    },
    [form, loading],
  );

  const onPollStatus = useCallback(
    async (
      collector: PollingCollector,
      onStatus: (status: PollingStatus) => void,
    ): Promise<() => void> =>
      pollStatus(
        status => {
          onStatus(status);
          if (status.status !== 'continue') {
            next({ collectors: [] }).catch(() => {
              // `error` is already updated by the hook.
            });
          }
        },
        { key: collector.key },
      ),
    [next, pollStatus],
  );

  const onStartAction = useCallback(async (): Promise<void> => {
    await onStart();
  }, [onStart]);

  const onLogout = useCallback(async (): Promise<void> => {
    try {
      await logoutUser();
    } catch {
      // The hook surfaces the error via `error`.
    } finally {
      setHasActiveSession(false);
      onAuthenticated?.();
    }
  }, [logoutUser, onAuthenticated, setHasActiveSession]);

  return {
    node,
    form,
    loading,
    error,
    idpError,
    fidoError,
    protectError,
    hasActiveSession,
    isSessionCheckRunning,
    onSubmit,
    onValidate,
    onFlowAction,
    onIdpAuthorize,
    onFidoCeremony,
    onPollStatus,
    onStart: onStartAction,
    onLogout,
  };
}
