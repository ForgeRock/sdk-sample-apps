/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { ScrollView, Text, View } from 'react-native';
import { open } from '@ping-identity/rn-browser';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import PingTextInput from './components/atoms/PingTextInput';
import AsyncActionButton from './components/molecules/AsyncActionButton';
import UserCodeConfirmationBanner from './components/molecules/UserCodeConfirmationBanner';
import PayloadViewer from './components/atoms/PayloadViewer';
import { commonStyles } from '../src/styles/common';
import type { RootStackParamList } from '../App';
import { formatError } from './utils/formatError';
import { extractUserCode } from './utils/extractUserCode';

/** Props for the separate device approval screen. */
type Props = NativeStackScreenProps<RootStackParamList, 'ApproveDevice'>;

/**
 * Mirrors the native Android ApproveDeviceScreen for browser approval.
 * DaVinci/Journey approval requires a separate configured orchestration flow
 * and is intentionally not synthesized here.
 */
export default function ApproveDeviceScreen({ route }: Props) {
  const [verificationUri, setVerificationUri] = useState(
    route.params?.verificationUri ?? '',
  );
  const [result, setResult] = useState('');
  const [error, setError] = useState('');
  const userCode = extractUserCode(verificationUri);

  const approveWithBrowser = async () => {
    setError('');
    setResult('');
    try {
      const response = await open(verificationUri.trim(), {
        callbackUrlScheme: 'org.forgerock.demo',
        redirectUri: 'org.forgerock.demo://oauth2redirect',
        ios: { browserMode: 'login', browserType: 'authSession' },
      });
      setResult(JSON.stringify(response, null, 2));
    } catch (cause) {
      setError(formatError(cause));
    }
  };

  return (
    <ScrollView
      contentContainerStyle={commonStyles.container}
      nestedScrollEnabled
    >
      <View style={commonStyles.card}>
        <Text style={commonStyles.journeySectionTitle}>
          Approve on This Device
        </Text>
        <Text style={commonStyles.userProfileSubText}>
          Paste the verification URL from another device and approve it here.
        </Text>
        <PingTextInput
          label="Verification URL"
          value={verificationUri}
          onChangeText={setVerificationUri}
          multiline
          autoCapitalize="none"
          autoCorrect={false}
          testID="approve-device-uri"
        />
        {userCode ? (
          <UserCodeConfirmationBanner
            userCode={userCode.toUpperCase()}
            testID="approve-device-user-code"
          />
        ) : null}
        <AsyncActionButton
          label="Approve with Browser"
          onPress={() => void approveWithBrowser()}
          disabled={!verificationUri.trim()}
          style={commonStyles.buttonGridItem}
        />
        {error ? (
          <Text
            testID="approve-device-error"
            style={commonStyles.userProfileSubText}
            selectable
          >
            {error}
          </Text>
        ) : null}
        {result ? <PayloadViewer payload={result} /> : null}
      </View>
    </ScrollView>
  );
}
