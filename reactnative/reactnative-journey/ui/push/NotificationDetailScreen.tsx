/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import type { PushClient, PushNotification } from '@ping-identity/rn-push';
import { getNumbersChallenge } from '@ping-identity/rn-push';
import { commonStyles } from '../../src/styles/common';
import { colors } from '../../src/styles/colors';

type Props = {
  notification: PushNotification;
  pushClient: PushClient;
  onDone: () => void;
};

export default function NotificationDetailScreen({
  notification,
  pushClient,
  onDone,
}: Props) {
  const [loading, setLoading] = useState(false);

  const approve = async (challengeResponse?: string) => {
    setLoading(true);
    try {
      if (notification.pushType === 'challenge' && challengeResponse != null) {
        await pushClient.approveChallengeNotification(
          notification.id,
          challengeResponse,
        );
      } else if (notification.pushType === 'biometric') {
        await pushClient.approveBiometricNotification(
          notification.id,
          'biometric',
        );
      } else {
        await pushClient.approveNotification(notification.id);
      }
      onDone();
    } catch (err) {
      Alert.alert(
        'Approve Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
    }
  };

  const deny = async () => {
    setLoading(true);
    try {
      await pushClient.denyNotification(notification.id);
      onDone();
    } catch (err) {
      Alert.alert(
        'Deny Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
    }
  };

  const numbers =
    notification.pushType === 'challenge' && notification.numbersChallenge
      ? getNumbersChallenge(notification)
      : null;

  return (
    <ScrollView contentContainerStyle={[commonStyles.container, { gap: 16 }]}>
      <Text style={commonStyles.journeyTitle}>Authentication Request</Text>

      {notification.messageText ? (
        <Text
          style={[commonStyles.userProfileSubText, { textAlign: 'center' }]}
        >
          {notification.messageText}
        </Text>
      ) : null}

      <View style={commonStyles.card}>
        <InfoRow label="Type" value={notification.pushType} />
        <InfoRow label="Notification ID" value={notification.id} />
        {notification.contextInfo ? (
          <InfoRow label="Context" value={notification.contextInfo} />
        ) : null}
      </View>

      {numbers != null ? (
        <View style={commonStyles.card}>
          <Text
            style={[commonStyles.journeySectionTitle, { textAlign: 'center' }]}
          >
            Select the number shown on screen:
          </Text>
          <View style={styles.numbersRow}>
            {numbers.map(n => (
              <TouchableOpacity
                key={n}
                style={[commonStyles.buttonPrimary, styles.numberButton]}
                onPress={() => void approve(String(n))}
                disabled={loading}
              >
                <Text style={[commonStyles.buttonText, styles.numberText]}>
                  {n}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      ) : (
        <View style={commonStyles.buttonGrid}>
          <TouchableOpacity
            style={[commonStyles.buttonDanger, commonStyles.buttonGridItem]}
            onPress={() => void deny()}
            disabled={loading}
          >
            <Text style={commonStyles.buttonText}>Deny</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              commonStyles.buttonPrimary,
              commonStyles.buttonGridItem,
              styles.approveButton,
            ]}
            onPress={() => void approve()}
            disabled={loading}
          >
            <Text style={commonStyles.buttonText}>Approve</Text>
          </TouchableOpacity>
        </View>
      )}

      {loading ? (
        <ActivityIndicator color={colors.primary} style={{ marginTop: 8 }} />
      ) : null}
    </ScrollView>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <Text style={commonStyles.inputLabel}>{label}</Text>
      <Text style={[commonStyles.userProfileSubText, styles.infoValue]}>
        {value}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  numbersRow: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    marginTop: 12,
  },
  numberButton: {
    width: 72,
    height: 72,
    borderRadius: 36,
    marginTop: 0,
  },
  numberText: {
    fontSize: 22,
    fontWeight: '700',
  },
  approveButton: {
    backgroundColor: colors.success,
  },
  infoRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 8,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 10,
    marginTop: 4,
  },
  infoValue: {
    flex: 1,
    textAlign: 'right',
    marginBottom: 0,
  },
});
