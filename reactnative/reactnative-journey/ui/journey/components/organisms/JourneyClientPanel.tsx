/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import type {
  JourneyClient,
  JourneyStartOptions,
} from '@ping-identity/rn-journey';
import { commonStyles } from '../../../../src/styles/common';
import { journeyClientPanelStyles as styles } from '../../../../src/styles/journeyStyles';
import { useJourneyClientPanelController } from '../../hooks/useJourneyClientPanelController';
import { SHOW_JOURNEY_DEBUG_PANEL } from '../../utils/clientPanel';
import JourneyContinuePanel from './JourneyContinuePanel';
import JourneyDebugPanel from './JourneyDebugPanel';
import JourneyBindingPinModal from './JourneyBindingPinModal';
import JourneyBindingUserKeyModal from './JourneyBindingUserKeyModal';

/**
 * Props for a self-contained Journey panel bound to a single Journey client.
 */
export type JourneyClientPanelProps = {
  /**
   * Journey client used for native instance resolution and callback execution.
   */
  journeyClient: JourneyClient;
  /**
   * Optional panel title consumed by parent route/screen compositions.
   */
  title?: string;
  /**
   * Optional Journey start flags used when panel-triggered start actions run.
   */
  startOptions?: JourneyStartOptions;
  /**
   * App return URI used by external IdP browser authorization.
   */
  externalIdpRedirectUri: string;
  /**
   * Optional initial journey name used to prefill start input state.
   */
  initialJourneyName?: string;
  /**
   * Enables one-time auto-start behavior when panel mounts without an active session.
   */
  autoStartOnMount?: boolean;
  /**
   * Optional callback invoked once when an authenticated Journey session is detected.
   */
  onAuthenticated?: () => void;
  /**
   * When true, waits for explicit user action on the success screen before invoking `onAuthenticated`.
   */
  requireSuccessConfirmation?: boolean;
};

/**
 * Renders a complete helper-driven Journey experience for one client instance.
 *
 * @param props - Panel props.
 * @returns Journey panel element.
 */
export default function JourneyClientPanel(
  props: JourneyClientPanelProps,
): React.ReactElement {
  const { onAuthenticated, requireSuccessConfirmation = false } = props;
  const {
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
  } = useJourneyClientPanelController(props);

  return (
    <View style={styles.container}>
      <JourneyBindingUserKeyModal request={userKeyRequest} />
      <JourneyBindingPinModal request={pinRequest} />
      <View style={commonStyles.card}>
        {showCallbackScreen ? (
          <JourneyContinuePanel
            form={form}
            loading={loading}
            pollingWaitMs={pollingWaitMs}
            resumeUrl={resumeUrl}
            onResumeUrlChange={setResumeUrl}
            onResume={onResume}
            onSubmit={onSubmit}
            onSelectIdpProvider={onSelectIdpProvider}
          />
        ) : null}

        {showSuccessScreen ? (
          <View style={styles.successActionsContainer}>
            <TouchableOpacity
              style={commonStyles.buttonPrimary}
              onPress={onLogout}
            >
              <Text style={commonStyles.buttonText}>Logout</Text>
            </TouchableOpacity>
            {requireSuccessConfirmation && onAuthenticated ? (
              <TouchableOpacity
                style={commonStyles.buttonSecondary}
                onPress={onContinueAfterSuccess}
              >
                <Text style={commonStyles.buttonTextSecondary}>Continue</Text>
              </TouchableOpacity>
            ) : null}
          </View>
        ) : null}

        {node?.type === 'ErrorNode' ? (
          <Text style={commonStyles.textError}>
            {typeof node.message === 'string'
              ? node.message
              : 'A server-side validation error occurred.'}
          </Text>
        ) : null}

        {node?.type === 'FailureNode' ? (
          <Text style={commonStyles.textError}>
            {typeof node.cause === 'string'
              ? node.cause
              : typeof node.message === 'string'
                ? node.message
                : 'An unexpected failure occurred.'}
          </Text>
        ) : null}

        {error ? (
          <Text style={commonStyles.textError}>
            {`[${error.code}] ${error.message}`}
          </Text>
        ) : null}

        {externalIdpBrowserError ? (
          <Text style={commonStyles.textError}>{externalIdpBrowserError}</Text>
        ) : null}

        {!showCallbackScreen &&
        !showSuccessScreen &&
        !loading &&
        !isSessionCheckRunning ? (
          <Text style={styles.autoPollingNote}>
            No active Journey flow. Start from Journey Configuration.
          </Text>
        ) : null}
      </View>
      {SHOW_JOURNEY_DEBUG_PANEL ? (
        <JourneyDebugPanel entries={debugEntries} onClear={clearDebugEntries} />
      ) : null}
    </View>
  );
}
