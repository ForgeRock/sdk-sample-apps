/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  useJourney,
  useJourneyForm,
  type JourneyCallbackType,
  type JourneyClient,
  type JourneyError,
  type JourneyFormResult,
  type JourneyNextInput,
  type JourneyNode,
  type JourneyStartOptions,
} from '@ping-identity/rn-journey';
import {
  createBindingClient,
  type BindingPrompt,
  type UserKeyOption,
} from '@ping-identity/rn-binding';
import { createFidoClient } from '@ping-identity/rn-fido';
import { createExternalIdpClient } from '@ping-identity/rn-external-idp';
import { open as openBrowser } from '@ping-identity/rn-browser';
import { PingError } from '@ping-identity/rn-types';
import { formatError } from '../../utils/formatError';
import { collectDeviceProfile } from '@ping-identity/rn-device-profile';
import { logger } from '@ping-identity/rn-logger';
import {
  resolveContinueNodeAutomationPolicy,
  resolvePollingWaitMs,
} from '../utils/clientPanel';
import { bindingIntegration } from '../integrations/bindingIntegration';
import { fidoIntegration } from '../integrations/fidoIntegration';
import { useJourneySessionController } from './useJourneySessionController';
import { useJourneyResumeController } from './useJourneyResumeController';
import { useJourneyDebugEntries } from './useJourneyDebugEntries';
import { useJourneyAutomationEffects } from './useJourneyAutomationEffects';
import { useJourneyDebugEffects } from './useJourneyDebugEffects';
import { useJourneyAutoStartEffect } from './useJourneyAutoStartEffect';
import { useJourneyAutoForwarder } from './useJourneyAutoForwarder';
import { useJourneyIntegrationRunner } from './useJourneyIntegrationRunner';

const SELECT_IDP_CALLBACK_TYPE: string = 'SelectIdpCallback';
const REDIRECT_CALLBACK_TYPE: string = 'RedirectCallback';
const IDP_CALLBACK_TYPES = new Set<string>(['IdPCallback', 'IdpCallback']);

// Callback types handled by the fido and binding integrations — passed to
// useJourneyForm so canSubmit is not blocked on integration_required fields.
const INTEGRATION_HANDLED_CALLBACK_TYPES = new Set<JourneyCallbackType>([
  'FidoRegistrationCallback',
  'FidoAuthenticationCallback',
  'DeviceBindingCallback',
  'DeviceSigningVerifierCallback',
]);

/**
 * Options for the Journey client panel controller hook.
 */
export type UseJourneyClientPanelControllerOptions = {
  /**
   * Journey client used for native instance resolution and callback execution.
   */
  journeyClient: JourneyClient;
  /**
   * Optional default journey name shown in the input.
   */
  initialJourneyName?: string;
  /**
   * Optional start options passed to `start(...)`.
   */
  startOptions?: JourneyStartOptions;
  /**
   * App return URI used by external IdP browser authorization.
   */
  externalIdpRedirectUri: string;
  /**
   * Enables auto-start when the panel mounts and no session/node is active.
   */
  autoStartOnMount?: boolean;
  /**
   * Optional callback invoked once when an authenticated Journey session is detected.
   */
  onAuthenticated?: () => void;
  /**
   * When true, waits for explicit user action on the success screen before invoking
   * `onAuthenticated`.
   */
  requireSuccessConfirmation?: boolean;
};

/**
 * Result contract consumed by `JourneyClientPanel`.
 */
export type UseJourneyClientPanelControllerResult = {
  /**
   * Active Journey node.
   */
  node: JourneyNode | null;
  /**
   * Headless helper form state for the active node.
   */
  form: JourneyFormResult;
  /**
   * Journey action loading state.
   */
  loading: boolean;
  /**
   * Last hook-level Journey error.
   */
  error: JourneyError | null;
  /**
   * Session bootstrap running state.
   */
  isSessionCheckRunning: boolean;
  /**
   * Debug log entries shown in the sample debug panel.
   */
  debugEntries: ReturnType<typeof useJourneyDebugEntries>['debugEntries'];
  /**
   * Clears current debug log entries.
   */
  clearDebugEntries: () => void;
  /**
   * Polling wait resolved from callback payload when present.
   */
  pollingWaitMs: number | null;
  /**
   * Resume URL input value.
   */
  resumeUrl: string;
  /**
   * Resume URL input setter.
   */
  setResumeUrl: (value: string) => void;
  /**
   * Executes manual journey resume.
   */
  onResume: () => Promise<void>;
  /**
   * Executes journey submit for current form state.
   */
  onSubmit: () => Promise<void>;
  /**
   * Selects an external IdP provider and immediately advances into browser authorization.
   */
  onSelectIdpProvider: (fieldId: string, provider: string) => Promise<void>;
  /**
   * Logs out the current user/session.
   */
  onLogout: () => Promise<void>;
  /**
   * Explicit success continuation used when success confirmation is required.
   */
  onContinueAfterSuccess: () => void;
  /**
   * True when callback panel should be shown.
   */
  showCallbackScreen: boolean;
  /**
   * True when success actions should be shown.
   */
  showSuccessScreen: boolean;
  /**
   * Error message from an external IdP browser authorization failure, separate from
   * the journey hook's `error` state.
   */
  externalIdpBrowserError: string | null;
  /**
   * Active PIN collection request, or null when no PIN prompt is needed.
   */
  pinRequest: {
    prompt: BindingPrompt;
    onSubmit: (pin: string) => void;
    onCancel: () => void;
  } | null;
  /**
   * Active user key selection request, or null when no key picker is needed.
   */
  userKeyRequest: {
    userKeys: UserKeyOption[];
    onSelect: (key: UserKeyOption) => void;
    onCancel: () => void;
  } | null;
};

type ExternalIdpIntegrationExecutionOptions = {
  continueOnAuthorizationCancel?: boolean;
};

type ExternalIdpIntegrationExecutionResult = {
  authorizationCancelled: boolean;
};

function trimStringValue(value: unknown): string | null {
  if (typeof value !== 'string') {
    return null;
  }
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

/**
 * Extracts a string at the given keys from an object literal, trimmed.
 */
function readRecordField(
  record: Record<string, unknown>,
  keys: string[],
): string | null {
  for (const key of keys) {
    const value = record[key];
    if (typeof value !== 'string') continue;
    const trimmed = value.trim();
    if (trimmed.length > 0) return trimmed;
  }
  return null;
}

function readOutputValue(output: unknown, name: string): unknown {
  if (!Array.isArray(output)) {
    return undefined;
  }

  return output
    .filter((item): item is Record<string, unknown> =>
      Boolean(item && typeof item === 'object' && !Array.isArray(item)),
    )
    .find(item => item.name === name)?.value;
}

function resolveUriScheme(uri: string | undefined): string | null {
  const normalized = uri?.trim();
  if (!normalized) {
    return null;
  }

  const match = /^([A-Za-z][A-Za-z0-9+.-]*):/.exec(normalized);
  return match?.[1] ?? null;
}

function resolveRedirectUrl(node: JourneyNode | null): string | null {
  if (node?.type !== 'ContinueNode') {
    return null;
  }

  const inputCallbacks =
    node.input &&
    typeof node.input === 'object' &&
    Array.isArray((node.input as Record<string, unknown>).callbacks)
      ? ((node.input as Record<string, unknown>).callbacks as unknown[])
      : [];
  const callbacks = [...(node.callbacks ?? []), ...inputCallbacks].filter(
    (callback): callback is Record<string, unknown> =>
      Boolean(
        callback && typeof callback === 'object' && !Array.isArray(callback),
      ),
  );
  const redirectCallback = callbacks.find(
    callback => callback.type === REDIRECT_CALLBACK_TYPE,
  );
  if (!redirectCallback) {
    return null;
  }
  const rawCallback =
    redirectCallback.raw &&
    typeof redirectCallback.raw === 'object' &&
    !Array.isArray(redirectCallback.raw)
      ? (redirectCallback.raw as Record<string, unknown>)
      : null;

  return (
    trimStringValue(redirectCallback.redirectUrl) ??
    trimStringValue(readOutputValue(redirectCallback.output, 'redirectUrl')) ??
    trimStringValue(readOutputValue(rawCallback?.output, 'redirectUrl'))
  );
}

/**
 * Removes native integration callbacks while preserving helper-built callback input.
 *
 * @param input - Submit payload built by `useJourneyForm`.
 * @param shouldFilterNativeCallbacks - True when native integrations already handled callbacks.
 * @returns Submit payload safe to pass to Journey `next()`.
 */
function buildNativeIntegrationSubmitInput(
  input: JourneyNextInput,
  shouldFilterNativeCallbacks: boolean,
): JourneyNextInput {
  if (!shouldFilterNativeCallbacks) {
    return input;
  }

  return {
    callbacks: (input.callbacks ?? []).filter(
      callback =>
        callback.type !== 'FidoRegistrationCallback' &&
        callback.type !== 'FidoAuthenticationCallback' &&
        !IDP_CALLBACK_TYPES.has(callback.type) &&
        callback.type !== SELECT_IDP_CALLBACK_TYPE,
    ),
  };
}

/**
 * Extracts a fallback device name from a device profile payload.
 */
function resolveDeviceNameFromDeviceProfile(profile: unknown): string | null {
  if (!profile || typeof profile !== 'object') return null;
  const platform = (profile as Record<string, unknown>).platform;
  if (!platform || typeof platform !== 'object') return null;
  return readRecordField(platform as Record<string, unknown>, [
    'model',
    'modelName',
  ]);
}

function isExternalIdpAuthorizationCancelledError(error: unknown): boolean {
  if (!error || typeof error !== 'object') {
    return false;
  }

  const code = (error as { code?: unknown }).code;
  return code === 'EXTERNAL_IDP_CANCELLED';
}

/**
 * Composes Journey sample panel behavior into a single controller hook.
 *
 * @param options - Controller options.
 * @returns Controller state and actions consumed by `JourneyClientPanel`.
 */
export function useJourneyClientPanelController(
  options: UseJourneyClientPanelControllerOptions,
): UseJourneyClientPanelControllerResult {
  const {
    journeyClient,
    initialJourneyName,
    startOptions,
    externalIdpRedirectUri,
    autoStartOnMount = false,
    onAuthenticated,
    requireSuccessConfirmation = false,
  } = options;

  const [journeyName, setJourneyName] = useState<string>(
    initialJourneyName ?? '',
  );
  const [externalIdpBrowserError, setExternalIdpBrowserError] = useState<
    string | null
  >(null);
  const defaultSystemDeviceNameRef = useRef<string | null>(null);
  const [pinRequest, setPinRequest] = useState<{
    prompt: BindingPrompt;
    onSubmit: (pin: string) => void;
    onCancel: () => void;
  } | null>(null);

  const [userKeyRequest, setUserKeyRequest] = useState<{
    userKeys: UserKeyOption[];
    onSelect: (key: UserKeyOption) => void;
    onCancel: () => void;
  } | null>(null);

  const binding = useMemo(
    () =>
      createBindingClient({
        ui: {
          // TODO(binding): Replace sample collectors with app-owned UX wiring in production.
          pinCollector: (prompt: BindingPrompt) =>
            new Promise((resolve, reject) => {
              setPinRequest({
                prompt,
                onSubmit: (pin: string) => {
                  setPinRequest(null);
                  resolve(pin);
                },
                onCancel: () => {
                  setPinRequest(null);
                  reject(new Error('cancelled'));
                },
              });
            }),
          userKeySelector: (keys: UserKeyOption[]) =>
            new Promise((resolve, reject) => {
              setUserKeyRequest({
                userKeys: keys,
                onSelect: (key: UserKeyOption) => {
                  setUserKeyRequest(null);
                  resolve(key);
                },
                onCancel: () => {
                  setUserKeyRequest(null);
                  reject(new Error('cancelled'));
                },
              });
            }),
        },
      }),
    [],
  );
  const fido = useMemo(() => createFidoClient({}), []);
  const externalIdpLogger = useMemo(() => logger({ level: 'debug' }), []);
  const externalIdpRedirectUriRef = useRef(externalIdpRedirectUri);
  const externalIdp = useMemo(
    () =>
      createExternalIdpClient({
        redirectUri: externalIdpRedirectUriRef.current,
        logger: externalIdpLogger,
      }),
    [externalIdpLogger],
  );
  const [node, actions] = useJourney();
  const { start, next, resume, user, logoutUser, dispose, loading, error } =
    actions;
  const form = useJourneyForm(node, {
    handledCallbackTypes: INTEGRATION_HANDLED_CALLBACK_TYPES,
  });
  const formRef = useRef(form);
  useEffect(() => {
    formRef.current = form;
  }, [form]);

  useEffect(() => {
    setJourneyName(initialJourneyName ?? '');
  }, [initialJourneyName]);

  const isContinueNode = node?.type === 'ContinueNode';
  const hasDeviceProfileCallback =
    form.getFieldsByType('DeviceProfileCallback').length > 0;
  const hasPollingWaitCallback =
    form.getFieldsByType('PollingWaitCallback').length > 0;
  const hasIdPCallback = form.fields.some(field =>
    IDP_CALLBACK_TYPES.has(field.ref.type as string),
  );
  const hasSelectIdpCallback = form.fields.some(
    field => (field.ref.type as string) === SELECT_IDP_CALLBACK_TYPE,
  );
  const hasExternalIdpCallback = hasIdPCallback || hasSelectIdpCallback;
  const hasSuspendedCallback =
    form.getFieldsByType('SuspendedTextOutputCallback').length > 0;
  const pollingWaitMs = useMemo<number | null>(
    () => resolvePollingWaitMs(form.fields),
    [form.fields],
  );

  // Stable signature used to dedupe automation for logically identical ContinueNodes.
  const continueNodeKey = useMemo<string>(() => {
    if (!isContinueNode || form.fields.length === 0) return '';
    return form.fields
      .map(field => `${field.ref.type}:${field.ref.typeIndex}:${field.id}`)
      .join('|');
  }, [form.fields, isContinueNode]);

  // Narrow key that scopes device-profile automation to relevant callback instances.
  const deviceProfileRequestKey = useMemo<string>(() => {
    if (!isContinueNode || !hasDeviceProfileCallback) return '';
    return `${continueNodeKey}:${form.fields
      .filter(field => field.ref.type === 'DeviceProfileCallback')
      .map(field => `${field.ref.typeIndex}`)
      .join(',')}`;
  }, [continueNodeKey, form.fields, hasDeviceProfileCallback, isContinueNode]);

  const automationPolicy = useMemo(
    () =>
      resolveContinueNodeAutomationPolicy({
        isContinueNode,
        loading,
        fields: form.fields,
        hasDeviceProfileCallback,
        hasPollingWaitCallback,
        hasSuspendedCallback,
        hasUnsupportedCallbacks: form.meta.hasUnsupported,
        pollingWaitMs,
      }),
    [
      form.fields,
      form.meta.hasUnsupported,
      hasDeviceProfileCallback,
      hasPollingWaitCallback,
      hasSuspendedCallback,
      isContinueNode,
      loading,
      pollingWaitMs,
    ],
  );

  const {
    hasActiveSession,
    setHasActiveSession,
    isSessionCheckRunning,
    onContinueAfterSuccess,
  } = useJourneySessionController({
    user,
    nodeType: node?.type,
    onAuthenticated,
    requireSuccessConfirmation,
  });

  const { debugEntries, appendDebug, clearDebugEntries } =
    useJourneyDebugEntries();
  const lastAutoIdpAuthNodeKeyRef = useRef<string | null>(null);
  const lastHandledRedirectUrlRef = useRef<string | null>(null);
  const hasCompletedExternalIdpRedirectRef = useRef<boolean>(false);

  const { resumeUrl, setResumeUrl, onResume } = useJourneyResumeController({
    hasSuspendedCallback,
    resume,
    appendDebug,
  });

  const resolveDefaultSystemDeviceName =
    useCallback(async (): Promise<string> => {
      if (defaultSystemDeviceNameRef.current) {
        return defaultSystemDeviceNameRef.current;
      }
      try {
        const profile = await collectDeviceProfile(['platform']);
        const resolved = resolveDeviceNameFromDeviceProfile(profile);
        if (resolved) {
          defaultSystemDeviceNameRef.current = resolved;
          return resolved;
        }
      } catch (resolveError) {
        appendDebug('Default device name fallback used', {
          reason: 'platform profile unavailable',
          error:
            resolveError instanceof PingError
              ? `[${resolveError.code}] ${resolveError.message}`
              : resolveError instanceof Error
                ? resolveError.message
                : String(resolveError),
        });
      }
      defaultSystemDeviceNameRef.current = 'Device';
      return defaultSystemDeviceNameRef.current;
    }, [appendDebug]);

  const readDeviceNameInput = useCallback(
    (fieldId: string): string | undefined => {
      const value = formRef.current.values[fieldId];
      return typeof value === 'string' ? value : undefined;
    },
    [],
  );

  const integrations = useMemo(
    () => [
      fidoIntegration(fido, {
        readDeviceNameInput,
        resolveDefaultDeviceName: resolveDefaultSystemDeviceName,
        continueOnAuthenticationCancel: true,
      }),
      bindingIntegration(binding, {
        readDeviceNameInput,
        resolveDefaultDeviceName: resolveDefaultSystemDeviceName,
      }),
    ],
    [binding, fido, readDeviceNameInput, resolveDefaultSystemDeviceName],
  );

  const runner = useJourneyIntegrationRunner({
    journeyClient,
    integrations,
    appendDebug,
  });

  // Pre-fill device-name text fields (FIDO registration, device binding)
  // using the platform profile so users see a sensible default.
  useEffect(() => {
    if (!isContinueNode) return;
    const deviceNameFields = form.fields.filter(
      field =>
        field.ref.type === 'FidoRegistrationCallback' ||
        field.ref.type === 'DeviceBindingCallback',
    );
    if (deviceNameFields.length === 0) return;

    const emptyFields = deviceNameFields.filter(field => {
      const value = form.values[field.id];
      return typeof value !== 'string' || value.trim().length === 0;
    });
    if (emptyFields.length === 0) return;

    let cancelled = false;
    void (async () => {
      const defaultDeviceName = await resolveDefaultSystemDeviceName();
      if (cancelled || defaultDeviceName.trim().length === 0) return;
      for (const field of emptyFields) {
        const currentValue = form.values[field.id];
        if (
          typeof currentValue === 'string' &&
          currentValue.trim().length > 0
        ) {
          continue;
        }
        form.setValue(field.id, defaultDeviceName);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [
    form,
    form.fields,
    form.values,
    isContinueNode,
    resolveDefaultSystemDeviceName,
  ]);

  useJourneyAutoForwarder({
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
  });

  const handleRedirectCallback = useCallback(
    async (targetNode: JourneyNode | null): Promise<boolean> => {
      const redirectUrl = resolveRedirectUrl(targetNode);
      if (!redirectUrl) {
        if (targetNode?.type === 'ContinueNode') {
          appendDebug('Journey external IdP redirect not found', {
            callbackTypes: targetNode.callbacks?.map(callback => callback.type),
          });
        }
        return false;
      }

      if (lastHandledRedirectUrlRef.current === redirectUrl) {
        return true;
      }
      lastHandledRedirectUrlRef.current = redirectUrl;

      appendDebug('Journey external IdP RedirectCallback received', {
        redirectUrl,
        reason:
          'Server returned RedirectCallback, so the sample app will use the browser flow instead of native IdpCallback authorization.',
      });

      const callbackUrlScheme = resolveUriScheme(externalIdpRedirectUri);
      if (!callbackUrlScheme) {
        setExternalIdpBrowserError(
          'External IdP redirect URI must include a custom URI scheme before the browser can open.',
        );
        appendDebug('Journey external IdP redirect blocked', {
          reason: 'Missing external IdP redirect URI scheme',
          redirectUrl,
        });
        return true;
      }

      appendDebug('Journey external IdP browser redirect requested', {
        redirectUrl,
        redirectUri: externalIdpRedirectUri,
        callbackUrlScheme,
      });

      try {
        setExternalIdpBrowserError(null);
        const browserResult = await openBrowser(redirectUrl, {
          callbackUrlScheme,
          redirectUri: externalIdpRedirectUri,
          ios: {
            browserMode: 'login',
            browserType: 'ephemeralAuthSession',
          },
        });

        if (browserResult.type === 'cancel') {
          lastHandledRedirectUrlRef.current = null;
          appendDebug('Journey external IdP browser redirect cancelled', {
            redirectUrl,
          });
          return true;
        }

        if (browserResult.type !== 'success' || !('url' in browserResult))
          return true;

        const resumedNode = await resume(browserResult.url as string);
        hasCompletedExternalIdpRedirectRef.current = true;
        appendDebug('Journey external IdP browser resume completed', {
          url: browserResult.url as string,
          callbackTypes:
            resumedNode.type === 'ContinueNode'
              ? resumedNode.callbacks?.map(callback => callback.type)
              : [],
        });
        return true;
      } catch (cause) {
        lastHandledRedirectUrlRef.current = null;
        const message =
          cause instanceof PingError
            ? `[${cause.code}] ${cause.message}`
            : cause instanceof Error
              ? cause.message
              : 'External IdP browser launch failed.';
        setExternalIdpBrowserError(message);
        appendDebug('Journey external IdP browser redirect failed', {
          redirectUrl,
          cause,
        });
        throw cause;
      }
    },
    [appendDebug, externalIdpRedirectUri, resume],
  );

  const runExternalIdpIntegrations = useCallback(
    async (
      executionOptions: ExternalIdpIntegrationExecutionOptions = {},
    ): Promise<ExternalIdpIntegrationExecutionResult> => {
      const { continueOnAuthorizationCancel = false } = executionOptions;
      let authorizationCancelled = false;

      if (!isContinueNode || !hasExternalIdpCallback) {
        return { authorizationCancelled };
      }

      const externalIdpFields = form.fields.filter(
        field =>
          (field.ref.type as string) === SELECT_IDP_CALLBACK_TYPE ||
          IDP_CALLBACK_TYPES.has(field.ref.type as string),
      );

      for (const field of externalIdpFields) {
        if ((field.ref.type as string) === SELECT_IDP_CALLBACK_TYPE) {
          const raw = form.values[field.id];
          const provider = typeof raw === 'string' ? raw.trim() : '';
          appendDebug('Journey external IdP select provider requested', {
            index: field.ref.typeIndex,
            hasProvider: provider.length > 0,
          });
          if (provider.length === 0) {
            appendDebug('Journey external IdP select provider skipped', {
              index: field.ref.typeIndex,
              reason: 'No provider selected',
            });
            continue;
          }
          await externalIdp.selectProviderForJourney(journeyClient, provider, {
            index: field.ref.typeIndex,
          });
          continue;
        }

        appendDebug('Journey external IdP authorize requested', {
          index: field.ref.typeIndex,
        });
        try {
          await externalIdp.authorizeForJourney(journeyClient, {
            index: field.ref.typeIndex,
          });
        } catch (authorizationError) {
          if (
            continueOnAuthorizationCancel &&
            isExternalIdpAuthorizationCancelledError(authorizationError)
          ) {
            authorizationCancelled = true;
            appendDebug('Journey external IdP authorization cancelled', {
              index: field.ref.typeIndex,
              behavior: 'continue_to_next',
            });
            continue;
          }
          throw authorizationError;
        }
      }
      return { authorizationCancelled };
    },
    [
      appendDebug,
      externalIdp,
      form.fields,
      form.values,
      hasExternalIdpCallback,
      isContinueNode,
      journeyClient,
    ],
  );

  useEffect(() => {
    if (!isContinueNode) {
      lastAutoIdpAuthNodeKeyRef.current = null;
      lastHandledRedirectUrlRef.current = null;
      return;
    }

    const hasNonExternalIdpIntegrationIssue = form.issues.some(
      issue =>
        issue.code === 'INTEGRATION_REQUIRED' &&
        !IDP_CALLBACK_TYPES.has(issue.callbackType ?? '') &&
        issue.callbackType !== SELECT_IDP_CALLBACK_TYPE,
    );
    const hasManualInput = form.fields.some(field => field.requiresUserInput);
    const canAutoRunIdpAuthOnly =
      !loading &&
      hasIdPCallback &&
      !hasSelectIdpCallback &&
      !hasManualInput &&
      !hasNonExternalIdpIntegrationIssue &&
      !hasDeviceProfileCallback &&
      !hasPollingWaitCallback &&
      !hasSuspendedCallback &&
      !form.meta.hasUnsupported &&
      continueNodeKey.length > 0;

    if (!canAutoRunIdpAuthOnly) {
      return;
    }

    if (lastAutoIdpAuthNodeKeyRef.current === continueNodeKey) {
      return;
    }
    lastAutoIdpAuthNodeKeyRef.current = continueNodeKey;

    void (async () => {
      try {
        setExternalIdpBrowserError(null);
        appendDebug('Journey auto external IdP authorization requested', {
          mode: 'auth-only continue node',
          continueNodeKey,
        });
        const idpResult = await runExternalIdpIntegrations({
          continueOnAuthorizationCancel: true,
        });
        if (idpResult.authorizationCancelled) {
          appendDebug(
            'Journey auto-continue after cancelled external IdP authorization',
            { continueNodeKey },
          );
        }
        const submitInput = buildNativeIntegrationSubmitInput(
          form.input,
          hasExternalIdpCallback,
        );
        appendDebug('Journey auto external IdP submit payload prepared', {
          originalCallbackCount: form.input.callbacks?.length ?? 0,
          submitCallbackCount: submitInput.callbacks?.length ?? 0,
        });
        await next(submitInput);
      } catch (cause) {
        setExternalIdpBrowserError(formatError(cause));
        appendDebug('Journey auto external IdP authorization failed', {
          continueNodeKey,
          cause,
        });
      }
    })();
  }, [
    appendDebug,
    continueNodeKey,
    form.fields,
    form.input,
    form.issues,
    form.meta.hasUnsupported,
    hasDeviceProfileCallback,
    hasIdPCallback,
    hasExternalIdpCallback,
    hasSelectIdpCallback,
    hasPollingWaitCallback,
    hasSuspendedCallback,
    isContinueNode,
    loading,
    next,
    runExternalIdpIntegrations,
  ]);

  const onSelectIdpProvider = useCallback(
    async (fieldId: string, provider: string): Promise<void> => {
      const field = form.getField(fieldId);
      if (!field || (field.ref.type as string) !== SELECT_IDP_CALLBACK_TYPE) {
        appendDebug('Journey external IdP provider selection skipped', {
          fieldId,
          reason: 'SelectIdpCallback field not found',
        });
        return;
      }

      const selectedProvider = provider.trim();
      if (selectedProvider.length === 0) {
        appendDebug('Journey external IdP provider selection skipped', {
          fieldId,
          reason: 'No provider selected',
        });
        return;
      }

      appendDebug('Journey external IdP provider selected', {
        index: field.ref.typeIndex,
        provider: selectedProvider,
      });
      setExternalIdpBrowserError(null);

      try {
        await externalIdp.selectProviderForJourney(
          journeyClient,
          selectedProvider,
          {
            index: field.ref.typeIndex,
          },
        );
        await next({});
      } catch (cause) {
        setExternalIdpBrowserError(formatError(cause));
        appendDebug('Journey external IdP provider selection failed', {
          fieldId,
          provider: selectedProvider,
          cause,
        });
      }
    },
    [appendDebug, externalIdp, form, journeyClient, next],
  );

  useJourneyAutomationEffects({
    node,
    loading,
    journeyClient,
    formCanSubmit: form.canSubmit,
    formInput: form.input,
    continueNodeKey,
    deviceProfileRequestKey,
    hasDeviceProfileCallback,
    automationPolicy,
    next,
  });

  useJourneyDebugEffects({
    node,
    error,
    appendDebug,
  });

  useEffect(() => {
    if (loading || !resolveRedirectUrl(node)) {
      return;
    }

    void handleRedirectCallback(node);
  }, [handleRedirectCallback, loading, node]);

  const onStart = useCallback(async (): Promise<boolean> => {
    setExternalIdpBrowserError(null);
    hasCompletedExternalIdpRedirectRef.current = false;
    lastHandledRedirectUrlRef.current = null;
    const trimmedJourneyName = journeyName.trim();
    if (!trimmedJourneyName) return false;

    try {
      await start(trimmedJourneyName, startOptions);
      form.reset();
      setResumeUrl('');
      return true;
    } catch {
      return false;
    }
  }, [form, journeyName, setResumeUrl, start, startOptions]);

  useJourneyAutoStartEffect({
    autoStartOnMount,
    loading,
    isSessionCheckRunning,
    hasActiveSession,
    node,
    journeyName,
    onStart,
    dispose,
  });

  const onSubmit = useCallback(async (): Promise<void> => {
    if (runner.hasUnhandledIntegrationIssue(form)) {
      appendDebug('Submit blocked: unhandled integration callback', {
        callbackTypes: form.issues
          .filter(
            issue =>
              issue.code === 'INTEGRATION_REQUIRED' &&
              (!issue.callbackType ||
                !runner.handledCallbackTypes.has(issue.callbackType)),
          )
          .map(issue => issue.callbackType),
      });
      return;
    }

    appendDebug('Journey submit requested', {
      callbacks: form.fields.map(field => ({
        type: field.ref.type,
        index: field.ref.typeIndex,
        value: form.values[field.id],
      })),
    });
    setExternalIdpBrowserError(null);

    // Match the native sample pattern: on integration failure, the native
    // SDK has already set `clientError` on the callback payload. Submit
    // anyway so AM's journey tree routes to the configured failure edge.
    try {
      await runner.runIntegrations(form);
    } catch (runError) {
      appendDebug('Integration failed; submitting to let server route', {
        error:
          runError instanceof PingError
            ? `[${runError.code}] ${runError.message}`
            : runError instanceof Error
              ? runError.message
              : String(runError),
      });
    }

    try {
      const idpResult = await runExternalIdpIntegrations({
        continueOnAuthorizationCancel: true,
      });
      if (idpResult.authorizationCancelled) {
        appendDebug(
          'Journey submit continues after cancelled external IdP authorization',
        );
      }
    } catch (idpCause) {
      setExternalIdpBrowserError(formatError(idpCause));
      appendDebug('Journey external IdP authorization failed', {
        cause: idpCause,
      });
      return;
    }

    try {
      const hasHandled =
        runner.hasHandledCallback(form) || hasExternalIdpCallback;
      const submitInput: JourneyNextInput = hasHandled
        ? buildNativeIntegrationSubmitInput(
            {
              callbacks: runner.filterCallbacksForSubmit(form.input.callbacks),
            },
            hasExternalIdpCallback,
          )
        : form.input;

      const nextNode = await next(submitInput);
      const handledRedirect = await handleRedirectCallback(nextNode);
      if (!handledRedirect) {
        hasCompletedExternalIdpRedirectRef.current = false;
      }
    } catch {
      // Error surfaces via Journey hook state and useJourneyDebugEffects.
    }
  }, [
    appendDebug,
    form,
    hasExternalIdpCallback,
    handleRedirectCallback,
    next,
    runExternalIdpIntegrations,
    runner,
  ]);

  const onLogout = useCallback(async (): Promise<void> => {
    try {
      await logoutUser();
    } finally {
      setHasActiveSession(false);
      setResumeUrl('');
      setExternalIdpBrowserError(null);
      hasCompletedExternalIdpRedirectRef.current = false;
      lastHandledRedirectUrlRef.current = null;
      form.reset();
    }
  }, [form, logoutUser, setHasActiveSession, setResumeUrl]);

  const showCallbackScreen = isContinueNode;
  const showSuccessScreen = node?.type === 'SuccessNode' || hasActiveSession;

  return {
    node,
    form,
    loading,
    error,
    isSessionCheckRunning,
    debugEntries,
    clearDebugEntries,
    pollingWaitMs,
    resumeUrl,
    setResumeUrl,
    onResume,
    onSubmit,
    onSelectIdpProvider,
    onLogout,
    onContinueAfterSuccess,
    showCallbackScreen,
    showSuccessScreen,
    externalIdpBrowserError,
    pinRequest,
    userKeyRequest,
  };
}
