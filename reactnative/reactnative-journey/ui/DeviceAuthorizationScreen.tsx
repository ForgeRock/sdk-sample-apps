/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Clipboard,
  Modal,
  Pressable,
  ScrollView,
  Text,
  TextStyle,
  View,
} from 'react-native';
import QRCode from 'react-native-qrcode-svg';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import {
  useDeviceAuthGrant,
  type OidcDeviceFlowStatus,
} from '@ping-identity/rn-oidc';
import type { RootStackParamList } from '../App';
import { colors } from '../src/styles/colors';
import { commonStyles } from '../src/styles/common';
import AsyncActionButton from './components/molecules/AsyncActionButton';
import CardSection from './components/molecules/CardSection';
import UserCodeConfirmationBanner from './components/molecules/UserCodeConfirmationBanner';
import PingTextInput from './components/atoms/PingTextInput';
import LabeledSwitchRow from './components/atoms/LabeledSwitchRow';
import { extractUserCode } from './utils/extractUserCode';
import { formatError } from './utils/formatError';

type Props = NativeStackScreenProps<RootStackParamList, 'DeviceAuthorization'>;

/**
 * Human-readable status text per {@link OidcDeviceFlowStatus}, matching the
 * strings used by the native Android sample's DeviceAuthorizationGrantViewModel.
 */
function statusMessage(status: OidcDeviceFlowStatus | null): string {
  switch (status?.type) {
    case 'started':
      return 'Open the URL and enter the user code.';
    case 'polling':
      return `Waiting for approval... (attempt ${status.pollCount})`;
    case 'success':
      return 'Authorization successful.';
    default:
      return '';
  }
}

/**
 * Terminal failure text per {@link OidcDeviceFlowStatus}, matching the Android
 * ViewModel's error strings.
 */
function terminalError(status: OidcDeviceFlowStatus | null): string {
  switch (status?.type) {
    case 'expired':
      return 'The device code has expired. Please start again.';
    case 'accessDenied':
      return 'Access denied by user.';
    case 'failure':
      return status.error.message || 'Device authorization failed.';
    default:
      return '';
  }
}

/** Renders a labelled value row with a clipboard copy affordance. */
function CopyableValueRow({
  label,
  value,
  valueStyle,
}: {
  label: string;
  value: string;
  valueStyle: TextStyle | TextStyle[];
}): React.ReactElement {
  const handleCopy = (): void => {
    Clipboard.setString(value);
  };

  return (
    <View>
      <Text style={commonStyles.deviceCopyLabel}>{label}</Text>
      <View style={commonStyles.deviceCopyValueRow}>
        <Text style={[commonStyles.deviceCopyValueText, valueStyle]} selectable>
          {value}
        </Text>
        <Pressable
          testID={`device-authorization-copy-${label
            .toLowerCase()
            .replace(/\s+/g, '-')}`}
          accessibilityLabel={`Copy ${label}`}
          onPress={handleCopy}
          style={commonStyles.deviceCopyButton}
        >
          <MaterialIcon name="content-copy" size={18} color={colors.gray} />
        </Pressable>
      </View>
    </View>
  );
}

/** Mirrors the native Android sample's RFC 8628 Device Authorization screen. */
export default function DeviceAuthorizationScreen({
  navigation,
}: Props): React.ReactElement {
  const [
    { status, authorizationResponse, isFlowActive, isLoading, isAuthenticated },
    actions,
  ] = useDeviceAuthGrant();
  const [showVerifySheet, setShowVerifySheet] = useState<boolean>(false);
  const [sheetVerificationUri, setSheetVerificationUri] = useState<string>('');
  const [codeConfirmed, setCodeConfirmed] = useState<boolean>(false);
  const [browserResult, setBrowserResult] = useState<string>('');

  const verificationUri =
    authorizationResponse?.verificationUriComplete ??
    authorizationResponse?.verificationUri ??
    '';
  const hasStarted = isFlowActive || Boolean(authorizationResponse);
  const isPolling = isLoading && status?.type === 'polling';
  const terminal = terminalError(status);
  const preStartError = !hasStarted ? terminal : null;
  const codeError = hasStarted ? terminal : null;

  // Navigate to the Token screen once authorization succeeds, mirroring the
  // Android sample's onSuccess behavior. The flow state is cleared afterwards
  // so returning to this screen shows a fresh Start card; isAuthenticated and
  // the approved device session are intentionally preserved.
  useEffect(() => {
    if (status?.type === 'success' && isAuthenticated) {
      navigation.navigate('Token');
      actions.clear();
    }
  }, [actions, isAuthenticated, navigation, status?.type]);

  const start = async (): Promise<void> => {
    try {
      await actions.authorize();
    } catch {
      // The hook exposes the typed error through shared state.
    }
  };

  const cancel = (): void => {
    actions.cancel();
  };

  const sheetUserCode =
    extractUserCode(sheetVerificationUri) ?? authorizationResponse?.userCode;
  const codeGateSatisfied = !sheetUserCode || codeConfirmed;

  const openVerifySheet = (): void => {
    setSheetVerificationUri(verificationUri);
    setCodeConfirmed(false);
    setShowVerifySheet(true);
  };

  const updateSheetVerificationUri = (value: string): void => {
    setSheetVerificationUri(value);
    setCodeConfirmed(false);
  };

  const approveWithJourney = (): void => {
    setShowVerifySheet(false);
    navigation.navigate('JourneyRoute', {
      verificationUri: sheetVerificationUri,
    });
  };

  const approveWithBrowser = async (): Promise<void> => {
    setBrowserResult('');
    try {
      const result = await actions.openVerificationUrl(sheetVerificationUri);
      setBrowserResult(
        result.type === 'cancel'
          ? 'Browser approval dismissed. Polling continues.'
          : 'Browser approval completed.',
      );
    } catch (cause) {
      setBrowserResult(formatError(cause));
    }
  };

  return (
    <ScrollView
      contentContainerStyle={commonStyles.container}
      nestedScrollEnabled
    >
      <CardSection
        icon={
          <MaterialIcon name="phone-android" size={48} color={colors.primary} />
        }
        title="Start"
        subtitle="Initiate the Device Authorization flow to get a user code and verification URL."
      >
        <View style={commonStyles.deviceAuthButtonRow}>
          <AsyncActionButton
            label={hasStarted ? 'Started' : 'Start'}
            onPress={() => {
              void start();
            }}
            loading={isLoading && !hasStarted}
            disabled={isLoading || hasStarted}
            style={commonStyles.deviceAuthButtonRowItem}
          />
          {hasStarted ? (
            <AsyncActionButton
              label="Cancel"
              variant="secondary"
              onPress={cancel}
              disabled={isLoading && !isPolling}
              style={commonStyles.deviceAuthButtonRowItem}
            />
          ) : null}
        </View>
        {preStartError ? (
          <Text
            testID="device-authorization-error"
            style={commonStyles.textError}
            selectable
          >
            {preStartError}
          </Text>
        ) : null}
        {hasStarted && authorizationResponse ? (
          <View
            testID="device-authorization-started"
            style={{ width: '100%', alignItems: 'center' }}
          >
            <Text style={commonStyles.deviceAuthSectionHeading}>
              Activate Your Device
            </Text>
            <Text style={commonStyles.deviceAuthSectionCaption}>
              Scan the QR code or visit the URL below and enter the code.
            </Text>
            <View
              testID="device-authorization-qr"
              accessible
              accessibilityLabel="QR code for device authorization"
              style={commonStyles.deviceQrBox}
            >
              <QRCode
                value={verificationUri}
                size={200}
                color="#000000"
                backgroundColor="#ffffff"
                quietZone={1}
              />
            </View>
            <CopyableValueRow
              label="User Code"
              value={authorizationResponse.userCode.toUpperCase()}
              valueStyle={commonStyles.deviceCopyValueCode}
            />
            <CopyableValueRow
              label="Verification URL"
              value={verificationUri}
              valueStyle={commonStyles.deviceCopyValueUrl}
            />
            {status ? (
              <Text
                testID={`device-authorization-${status.type}`}
                style={commonStyles.deviceAuthStatusText}
              >
                {statusMessage(status)}
              </Text>
            ) : null}
            {codeError ? (
              <Text
                testID="device-authorization-error"
                style={commonStyles.textError}
                selectable
              >
                {codeError}
              </Text>
            ) : null}
            {isPolling ? (
              <ActivityIndicator
                testID="device-authorization-polling"
                style={{ marginTop: 16 }}
              />
            ) : null}
          </View>
        ) : null}
      </CardSection>

      <CardSection
        icon={
          <MaterialIcon name="verified-user" size={48} color={colors.success} />
        }
        title="Verify"
        subtitle="Perform verification via Journey or Browser to complete the authorization."
      >
        <AsyncActionButton
          label="Verify"
          variant="secondary"
          onPress={openVerifySheet}
        />
      </CardSection>

      <Modal
        visible={showVerifySheet}
        transparent
        animationType="slide"
        onRequestClose={() => setShowVerifySheet(false)}
      >
        <Pressable
          style={commonStyles.deviceAuthSheetOverlay}
          onPress={() => setShowVerifySheet(false)}
        >
          <Pressable
            style={commonStyles.deviceAuthSheet}
            onPress={() => undefined}
          >
            <View style={commonStyles.deviceAuthSheetHandle} />
            <ScrollView
              nestedScrollEnabled
              showsVerticalScrollIndicator
              keyboardShouldPersistTaps="handled"
            >
              <MaterialIcon
                name="verified-user"
                size={72}
                color={colors.primary}
                style={{ alignSelf: 'center' }}
              />
              <Text style={commonStyles.deviceAuthSheetTitle}>
                Approve on This Device
              </Text>
              <Text style={commonStyles.deviceAuthSheetBody}>
                Paste the verification URL from another device (including the
                user_code) and tap Approve to authorize it here.
              </Text>
              <Text style={commonStyles.deviceAuthSheetInputLabel}>
                VERIFICATION URL
              </Text>
              <PingTextInput
                value={sheetVerificationUri}
                onChangeText={updateSheetVerificationUri}
                multiline
                autoCapitalize="none"
                autoCorrect={false}
                testID="approve-device-uri"
              />
              {sheetUserCode ? (
                <>
                  <UserCodeConfirmationBanner
                    userCode={sheetUserCode.toUpperCase()}
                    testID="approve-device-user-code"
                  />
                  <LabeledSwitchRow
                    label="I confirm this code matches the requesting device"
                    value={codeConfirmed}
                    onValueChange={() => setCodeConfirmed(value => !value)}
                  />
                </>
              ) : null}
              <View style={{ marginTop: 24, gap: 12 }}>
                <AsyncActionButton
                  label="Approve with Journey"
                  onPress={approveWithJourney}
                  disabled={!sheetVerificationUri.trim() || !codeGateSatisfied}
                />
                <AsyncActionButton
                  label="Approve in Another App"
                  onPress={() =>
                    navigation.navigate('ApproveDevice', {
                      verificationUri: sheetVerificationUri,
                    })
                  }
                  disabled={!sheetVerificationUri.trim()}
                />
                <AsyncActionButton
                  label="Approve with Browser"
                  variant="secondary"
                  onPress={() => {
                    void approveWithBrowser();
                  }}
                  disabled={!sheetVerificationUri.trim()}
                />
                {browserResult ? (
                  <Text style={commonStyles.deviceAuthSheetBody}>
                    {browserResult}
                  </Text>
                ) : null}
              </View>
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>
    </ScrollView>
  );
}
