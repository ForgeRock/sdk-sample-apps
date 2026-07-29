/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useMemo } from 'react';
import { Text, TouchableOpacity } from 'react-native';
import type {
  JourneyCallbackType,
  JourneyFormResult,
} from '@ping-identity/rn-journey';
import {
  callbackType,
  nativeExtensionCallbackType,
} from '@ping-identity/rn-types';
import { commonStyles } from '../../../../src/styles/common';
import { journeyClientPanelStyles as styles } from '../../../../src/styles/journeyStyles';
import JourneyFieldRenderer from '../molecules/renderers/JourneyFieldRenderer';
import { DEFAULT_AUTO_POLLING_WAIT_MS } from '../../utils/clientPanel';
import PingTextInput from '../../../components/atoms/PingTextInput';

/**
 * Props for rendering the active `ContinueNode` callback area.
 */
export type JourneyContinuePanelProps = {
  /**
   * Headless form contract resolved for the active ContinueNode.
   */
  form: JourneyFormResult;
  /**
   * True while a Journey action is currently in-flight.
   */
  loading: boolean;
  /**
   * Polling wait time resolved from PollingWaitCallback payload, in milliseconds.
   */
  pollingWaitMs: number | null;
  /**
   * Current resume URI field value shown when suspended callbacks are active.
   */
  resumeUrl: string;
  /**
   * Resume URI input updater.
   *
   * @param value - Next resume URI value.
   * @returns Void.
   */
  onResumeUrlChange: (value: string) => void;
  /**
   * Executes resume action with current `resumeUrl`.
   *
   * @returns Promise resolved after resume attempt completes.
   */
  onResume: () => Promise<void>;
  /**
   * Executes submit action for current callback form input.
   *
   * @returns Promise resolved after submit attempt completes.
   */
  onSubmit: () => Promise<void>;
  /**
   * Selects an external IdP provider and immediately advances into browser authorization.
   *
   * @param fieldId - Normalized SelectIdpCallback field id.
   * @param provider - Provider identifier selected by the user.
   * @returns Promise resolved after provider selection handling completes.
   */
  onSelectIdpProvider?: (fieldId: string, provider: string) => Promise<void>;
};

/**
 * Renders callback fields and continuation actions for a `ContinueNode`.
 *
 * @param props - Component props.
 * @returns Continue node panel markup.
 */
export default function JourneyContinuePanel(
  props: JourneyContinuePanelProps,
): React.ReactElement {
  const {
    form,
    loading,
    pollingWaitMs,
    resumeUrl,
    onResumeUrlChange,
    onResume,
    onSubmit,
    onSelectIdpProvider,
  } = props;
  const { fields, values, meta, setValue } = form;

  const callbackTypes = useMemo<Set<JourneyCallbackType>>(
    () => new Set(fields.map(field => field.ref.type)),
    [fields],
  );

  // Callbacks silently handled by registered integrations (auto-forwarded or
  // panel-level effects) — not surfaced as blocking issues in the UI.
  const isAutoHandledIntegrationCallback = useCallback(
    (type: JourneyCallbackType): boolean =>
      type === callbackType.DeviceProfileCallback ||
      type === nativeExtensionCallbackType.FidoRegistrationCallback ||
      type === nativeExtensionCallbackType.FidoAuthenticationCallback ||
      type === nativeExtensionCallbackType.IdpCallback ||
      type === nativeExtensionCallbackType.SelectIdpCallback ||
      type === 'DeviceBindingCallback' ||
      type === 'DeviceSigningVerifierCallback',
    [],
  );

  const hasDeviceProfileCallback = callbackTypes.has(
    callbackType.DeviceProfileCallback,
  );
  const hasSelectIdpCallback = fields.some(
    field => field.ref.type === nativeExtensionCallbackType.SelectIdpCallback,
  );
  const hasSuspendedCallback = callbackTypes.has(
    callbackType.SuspendedTextOutputCallback,
  );
  const hasPollingWaitCallback = callbackTypes.has(
    callbackType.PollingWaitCallback,
  );
  const hasManualSubmit = fields.some(
    field =>
      field.requiresUserInput &&
      !(hasPollingWaitCallback && field.ref.type === 'ConfirmationCallback'),
  );

  // Derive blocking state and display info from form.issues — single source of truth.
  const blockingIntegrationCallbackTypes = useMemo<JourneyCallbackType[]>(
    () =>
      Array.from(
        new Set(
          form.issues
            .filter(
              issue =>
                issue.code === 'INTEGRATION_REQUIRED' &&
                issue.callbackType != null &&
                !isAutoHandledIntegrationCallback(issue.callbackType),
            )
            .map(issue => issue.callbackType as JourneyCallbackType),
        ),
      ),
    [form.issues, isAutoHandledIntegrationCallback],
  );
  const hasBlockingIntegration = blockingIntegrationCallbackTypes.length > 0;

  const unsupportedCallbackTypes = useMemo<JourneyCallbackType[]>(
    () =>
      Array.from(
        new Set(
          form.issues
            .filter(issue => issue.code === 'UNSUPPORTED_CALLBACK')
            .map(issue => issue.callbackType)
            .filter(
              (value): value is JourneyCallbackType =>
                typeof value === 'string' && value.length > 0,
            ),
        ),
      ),
    [form.issues],
  );
  const hasUnsupportedCallbacks = meta.hasUnsupported;

  const blockingIssueMessages = useMemo<string[]>(
    () =>
      form.issues
        .filter(
          issue =>
            issue.code === 'UNSUPPORTED_CALLBACK' ||
            (issue.code === 'INTEGRATION_REQUIRED' &&
              issue.callbackType != null &&
              !isAutoHandledIntegrationCallback(issue.callbackType)),
        )
        .map(issue => issue.message),
    [form.issues, isAutoHandledIntegrationCallback],
  );

  // True when every field is silently handled by a registered integration —
  // the auto-forwarder owns submission, so a Continue button would be redundant.
  // FIDO registration and device binding render a device-name field so they
  // always keep the Continue button.
  const isAutoForwardedByIntegration =
    fields.length > 0 &&
    fields.every(
      field =>
        field.executionMode === 'integration_required' &&
        isAutoHandledIntegrationCallback(field.ref.type) &&
        field.ref.type !== 'FidoRegistrationCallback' &&
        field.ref.type !== 'DeviceBindingCallback',
    );

  const canAutoAdvanceWithContinueButton =
    !hasManualSubmit &&
    !hasBlockingIntegration &&
    !hasUnsupportedCallbacks &&
    !hasDeviceProfileCallback &&
    !hasSelectIdpCallback &&
    !hasSuspendedCallback &&
    !hasPollingWaitCallback &&
    !isAutoForwardedByIntegration;

  const shouldShowContinueButton =
    hasManualSubmit || canAutoAdvanceWithContinueButton;

  // form.canSubmit is the single source of truth — true when all fields are
  // filled and no unhandled integration or unsupported callbacks remain.
  const submitDisabled = loading || !form.canSubmit;

  const pollingWaitSeconds = Math.max(
    1,
    Math.ceil((pollingWaitMs ?? DEFAULT_AUTO_POLLING_WAIT_MS) / 1000),
  );

  return (
    <>
      {/* `setFieldValue` writes into `useJourneyForm` state, consumed as `form.input` on submit. */}
      {fields.map(field => (
        <JourneyFieldRenderer
          key={field.id}
          field={field}
          currentValue={values[field.id]}
          setFieldValue={setValue}
          onSelectIdpProvider={onSelectIdpProvider}
        />
      ))}

      {hasBlockingIntegration ? (
        <>
          <Text style={styles.blockingNote}>
            This node includes callbacks that require extra native integrations
            (Protect, IdP, ReCaptcha, or Binding). Configure those modules to
            continue this journey.
          </Text>
          <Text style={styles.blockingNote}>
            Integration-required callbacks:{' '}
            {blockingIntegrationCallbackTypes.join(', ') || 'Unknown'}
          </Text>
        </>
      ) : null}

      {blockingIssueMessages.length > 0 ? (
        <Text style={styles.blockingNote}>
          Blocking reasons: {blockingIssueMessages.join(' | ')}
        </Text>
      ) : null}

      {hasUnsupportedCallbacks ? (
        <>
          <Text style={styles.blockingNote}>
            This node includes callback types not handled by the helper submit
            planner. Add custom handling for these callbacks to continue.
          </Text>
          <Text style={styles.blockingNote}>
            Unsupported callbacks:{' '}
            {unsupportedCallbackTypes.join(', ') || 'Unknown'}
          </Text>
        </>
      ) : null}

      {!hasManualSubmit && hasDeviceProfileCallback ? (
        <Text style={styles.autoPollingNote}>
          Device profile callback detected. Collecting automatically.
        </Text>
      ) : null}

      {hasSuspendedCallback ? (
        <>
          <PingTextInput
            containerStyle={styles.topGap}
            label="Resume URL"
            value={resumeUrl}
            onChangeText={onResumeUrlChange}
            placeholder="myapp://oauth2redirect?..."
            autoCapitalize="none"
          />
          <TouchableOpacity
            style={[
              commonStyles.buttonSecondary,
              loading ? styles.disabledButton : null,
            ]}
            onPress={onResume}
            disabled={loading}
          >
            <Text style={commonStyles.buttonTextSecondary}>Resume</Text>
          </TouchableOpacity>
        </>
      ) : null}

      {shouldShowContinueButton ? (
        <TouchableOpacity
          style={[
            commonStyles.buttonPrimary,
            submitDisabled && styles.disabledButton,
          ]}
          onPress={onSubmit}
          disabled={submitDisabled}
        >
          <Text style={commonStyles.buttonText}>Continue</Text>
        </TouchableOpacity>
      ) : null}

      {!hasManualSubmit && hasPollingWaitCallback ? (
        <Text style={styles.autoPollingNote}>
          Polling callback detected. Continuing automatically in{' '}
          {pollingWaitSeconds}s.
        </Text>
      ) : null}
    </>
  );
}
