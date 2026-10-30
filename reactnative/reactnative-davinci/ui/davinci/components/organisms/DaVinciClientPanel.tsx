/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ActivityIndicator, Text, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';
import { davinciScreenStyles } from '../../../../src/styles/davinciStyles';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import EmptyStateCard from '../../../components/molecules/EmptyStateCard';
import UserCodeConfirmationBanner from '../../../components/molecules/UserCodeConfirmationBanner';
import { useDaVinciClientPanelController } from '../../hooks/useDaVinciClientPanelController';
import { extractUserCode } from '../../../utils/extractUserCode';
import DaVinciContinueNodePanel from './DaVinciContinueNodePanel';

/**
 * Props for {@link DaVinciClientPanel}.
 */
export type DaVinciClientPanelProps = {
  /**
   * Optional callback fired after the user dismisses a `SuccessNode`.
   *
   * @remarks
   * Use this to navigate away from the DaVinci screen on success.
   */
  onAuthenticated?: () => void;
  /**
   * Optional callback fired when the user taps "User Profile".
   *
   * @remarks
   * Use this to navigate to the user profile screen.
   */
  onUserProfile?: () => void;
  /**
   * Optional RFC 8628 `verification_uri_complete` used when this device is the
   * approving device in a device authorization grant. Passed to DaVinci
   * `start()` so the flow approves the requesting device.
   */
  verificationUri?: string;
  /**
   * Redirect URI of the selected DaVinci configuration, used by social login.
   */
  externalIdpRedirectUri?: string;
};

/**
 * Top-level DaVinci sample organism — orchestrates loading, success, error,
 * and continue states for a single DaVinci client.
 *
 * @remarks
 * Must be rendered inside a `DaVinciProvider` so that
 * {@link useDaVinciClientPanelController} can resolve a client.
 *
 * @param props Panel props.
 * @returns DaVinci client panel element.
 */
export default function DaVinciClientPanel(
  props: DaVinciClientPanelProps,
): React.ReactElement {
  const {
    onAuthenticated,
    onUserProfile,
    verificationUri,
    externalIdpRedirectUri,
  } = props;
  const verificationUserCode = verificationUri
    ? extractUserCode(verificationUri)
    : undefined;
  const {
    node,
    form,
    loading,
    error,
    idpError,
    fidoError,
    hasActiveSession,
    isSessionCheckRunning,
    onSubmit,
    onValidate,
    onFlowAction,
    onIdpAuthorize,
    onFidoCeremony,
    onPollStatus,
    onStart,
    onLogout,
  } = useDaVinciClientPanelController({
    onAuthenticated,
    verificationUri,
    externalIdpRedirectUri,
  });

  return (
    <View style={davinciScreenStyles.panel}>
      {verificationUserCode ? (
        <UserCodeConfirmationBanner
          userCode={verificationUserCode.toUpperCase()}
          testID="davinci-panel-user-code"
        />
      ) : null}
      <View style={commonStyles.card}>
        {node?.type === 'ContinueNode' ? (
          <DaVinciContinueNodePanel
            node={node}
            form={form}
            loading={loading}
            onSubmit={onSubmit}
            onValidate={onValidate}
            onFlowAction={onFlowAction}
            onIdpAuthorize={onIdpAuthorize}
            onFidoCeremony={onFidoCeremony}
            onPollStatus={onPollStatus}
          />
        ) : null}

        {node?.type === 'SuccessNode' || hasActiveSession ? (
          <View style={davinciScreenStyles.successCard}>
            <Text style={davinciScreenStyles.successTitle}>Authenticated</Text>
            <Text style={davinciScreenStyles.successText}>
              You have completed the DaVinci flow successfully.
            </Text>
            <AsyncActionButton label="Logout" onPress={onLogout} />
            {onUserProfile ? (
              <AsyncActionButton
                label="User Profile"
                onPress={onUserProfile}
                variant="secondary"
              />
            ) : null}
            <AsyncActionButton
              label="Run again"
              onPress={onStart}
              variant="secondary"
            />
          </View>
        ) : null}

        {node?.type === 'ErrorNode' ? (
          <EmptyStateCard
            title="The server reported an error"
            message={node.message || 'Please try again.'}
            ctaLabel="Retry"
            onCtaPress={onStart}
          />
        ) : null}

        {node?.type === 'FailureNode' ? (
          <EmptyStateCard
            title="Flow failed"
            message={node.message || 'The DaVinci flow failed unexpectedly.'}
            ctaLabel="Retry"
            onCtaPress={onStart}
          />
        ) : null}

        {!node && !loading && !hasActiveSession && !isSessionCheckRunning ? (
          <EmptyStateCard
            title="DaVinci"
            message="Start a DaVinci flow to authenticate."
            ctaLabel="Start flow"
            onCtaPress={onStart}
          />
        ) : null}

        {idpError ? (
          <EmptyStateCard
            title="Sign-in failed"
            message={idpError}
            ctaLabel="Retry"
            onCtaPress={onStart}
          />
        ) : null}

        {fidoError ? (
          <EmptyStateCard
            title="Passkey action failed"
            message={fidoError}
            ctaLabel="Retry"
            onCtaPress={onStart}
          />
        ) : null}

        {error ? (
          <Text style={commonStyles.textError} selectable>
            {`[${error.code}] ${error.message}`}
          </Text>
        ) : null}
      </View>

      {loading ? (
        <View style={davinciScreenStyles.loadingOverlay} pointerEvents="auto">
          <ActivityIndicator size="large" color={colors.white} />
        </View>
      ) : null}
    </View>
  );
}
