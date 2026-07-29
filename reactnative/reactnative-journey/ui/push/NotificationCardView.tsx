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
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type {
  PushClient,
  PushCredential,
  PushNotification,
} from '@ping-identity/rn-push';
import { getNumbersChallenge } from '@ping-identity/rn-push';
import { colors } from '../../src/styles/colors';
import { commonStyles } from '../../src/styles/common';

type Props = {
  notification: PushNotification;
  /** Matching enrolled credential — used to display issuer and account name. */
  credential: PushCredential | undefined;
  pushClient: PushClient;
  /** Called after any action (approve, deny, cancel) so the parent can refresh state. */
  onDone: () => void;
};

function isExpired(n: PushNotification): boolean {
  return Date.now() > n.createdAt + n.ttl * 1000;
}

/**
 * Renders the appropriate card for a push notification based on its `pushType`:
 * - `default`   — simple Approve / Deny buttons
 * - `challenge` — number-matching UI (tap the number shown on the other device)
 * - `biometric` — biometric prompt via `approveBiometricNotification`
 *
 * Expired notifications show the expiry badge and hide action buttons.
 */
export default function NotificationCardView({
  notification: n,
  credential,
  pushClient,
  onDone,
}: Props) {
  if (n.pushType === 'challenge') {
    return (
      <ChallengeCard
        n={n}
        credential={credential}
        pushClient={pushClient}
        onDone={onDone}
      />
    );
  }
  if (n.pushType === 'biometric') {
    return (
      <BiometricCard
        n={n}
        credential={credential}
        pushClient={pushClient}
        onDone={onDone}
      />
    );
  }
  return (
    <DefaultCard
      n={n}
      credential={credential}
      pushClient={pushClient}
      onDone={onDone}
    />
  );
}

function CardHeader({
  n,
  iconName,
  title,
  credential,
}: {
  n: PushNotification;
  iconName: string;
  title: string;
  credential: PushCredential | undefined;
}) {
  const expired = isExpired(n);
  return (
    <>
      <View style={styles.header}>
        <View style={styles.iconBadge}>
          <MaterialIcon name={iconName} size={20} color={colors.white} />
        </View>
        <View style={styles.headerText}>
          <Text style={styles.cardTitle}>{title}</Text>
          <Text style={styles.timestamp}>{relativeTime(n.createdAt)}</Text>
        </View>
        {expired && (
          <View style={styles.expiredBadge}>
            <MaterialIcon name="schedule" size={14} color="#FF9500" />
            <Text style={styles.expiredText}>Expired</Text>
          </View>
        )}
      </View>
      {credential && (
        <Text style={styles.credentialText}>
          {credential.displayIssuer} · {credential.displayAccountName}
        </Text>
      )}
      {n.messageText ? (
        <Text style={styles.messageText}>{n.messageText}</Text>
      ) : null}
    </>
  );
}

function DefaultCard({
  n,
  credential,
  pushClient,
  onDone,
}: Omit<Props, 'notification'> & { n: PushNotification }) {
  const [loading, setLoading] = useState(false);
  const expired = isExpired(n);

  const approve = async () => {
    setLoading(true);
    try {
      await pushClient.approveNotification(n.id);
    } catch (err) {
      Alert.alert(
        'Approve Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  const deny = async () => {
    setLoading(true);
    try {
      await pushClient.denyNotification(n.id);
    } catch (err) {
      Alert.alert(
        'Deny Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  return (
    <View style={commonStyles.card}>
      <CardHeader
        n={n}
        iconName="touch-app"
        title="Authentication Request"
        credential={credential}
      />
      {!expired && (
        <View style={styles.buttonRow}>
          <TouchableOpacity
            style={[styles.btn, styles.btnDeny]}
            onPress={() => void deny()}
            disabled={loading}
          >
            <MaterialIcon name="close" size={18} color={colors.white} />
            <Text style={styles.btnText}>Deny</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.btn, styles.btnApprove]}
            onPress={() => void approve()}
            disabled={loading}
          >
            <MaterialIcon name="check" size={18} color={colors.white} />
            <Text style={styles.btnText}>Approve</Text>
          </TouchableOpacity>
        </View>
      )}
      {loading && (
        <ActivityIndicator color={colors.primary} style={styles.spinner} />
      )}
    </View>
  );
}

function ChallengeCard({
  n,
  credential,
  pushClient,
  onDone,
}: Omit<Props, 'notification'> & { n: PushNotification }) {
  const [loading, setLoading] = useState(false);
  const expired = isExpired(n);
  const numbers = n.numbersChallenge ? getNumbersChallenge(n) : [];

  const approve = async (response: string) => {
    setLoading(true);
    try {
      await pushClient.approveChallengeNotification(n.id, response);
    } catch (err) {
      Alert.alert(
        'Approve Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  const deny = async () => {
    setLoading(true);
    try {
      await pushClient.denyNotification(n.id);
    } catch (err) {
      Alert.alert(
        'Deny Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  const cancel = async () => {
    setLoading(true);
    try {
      await pushClient.denyNotification(n.id);
    } catch (err) {
      Alert.alert(
        'Cancel Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  return (
    <View style={commonStyles.card}>
      <CardHeader
        n={n}
        iconName="pin"
        title="Challenge Authentication"
        credential={credential}
      />
      {!expired && (
        <View style={styles.challengeBody}>
          <Text style={styles.challengePrompt}>
            Select the number shown on your other device
          </Text>
          {numbers.length > 0 ? (
            <>
              <View style={styles.numbersRow}>
                {numbers.map(num => (
                  <TouchableOpacity
                    key={num}
                    style={styles.numberCircle}
                    onPress={() => void approve(String(num))}
                    disabled={loading}
                  >
                    <Text style={styles.numberText}>{num}</Text>
                  </TouchableOpacity>
                ))}
              </View>
              <TouchableOpacity
                style={styles.cancelBtn}
                onPress={() => void cancel()}
                disabled={loading}
              >
                <Text style={styles.cancelText}>Cancel Authentication</Text>
              </TouchableOpacity>
            </>
          ) : (
            <>
              <Text style={commonStyles.textError}>
                No challenge numbers available
              </Text>
              <TouchableOpacity
                style={[styles.btn, styles.btnDeny, { marginTop: 12 }]}
                onPress={() => void deny()}
                disabled={loading}
              >
                <MaterialIcon name="close" size={18} color={colors.white} />
                <Text style={styles.btnText}>Close</Text>
              </TouchableOpacity>
            </>
          )}
        </View>
      )}
      {loading && (
        <ActivityIndicator color={colors.primary} style={styles.spinner} />
      )}
    </View>
  );
}

function BiometricCard({
  n,
  credential,
  pushClient,
  onDone,
}: Omit<Props, 'notification'> & { n: PushNotification }) {
  const [loading, setLoading] = useState(false);
  const expired = isExpired(n);

  const approve = async () => {
    setLoading(true);
    try {
      await pushClient.approveBiometricNotification(n.id, 'biometric');
    } catch (err) {
      Alert.alert(
        'Approve Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  const deny = async () => {
    setLoading(true);
    try {
      await pushClient.denyNotification(n.id);
    } catch (err) {
      Alert.alert(
        'Deny Failed',
        err instanceof Error ? err.message : String(err),
      );
    } finally {
      setLoading(false);
      onDone();
    }
  };

  return (
    <View style={commonStyles.card}>
      <CardHeader
        n={n}
        iconName="fingerprint"
        title="Biometric Authentication"
        credential={credential}
      />
      {!expired && (
        <View style={styles.challengeBody}>
          <Text style={styles.challengePrompt}>
            Use biometric authentication to approve this request
          </Text>
          <View style={styles.buttonRow}>
            <TouchableOpacity
              style={[styles.btn, styles.btnDeny]}
              onPress={() => void deny()}
              disabled={loading}
            >
              <MaterialIcon name="close" size={18} color={colors.white} />
              <Text style={styles.btnText}>Deny</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.btn, styles.btnApprove]}
              onPress={() => void approve()}
              disabled={loading}
            >
              <MaterialIcon name="fingerprint" size={18} color={colors.white} />
              <Text style={styles.btnText}>Authenticate</Text>
            </TouchableOpacity>
          </View>
        </View>
      )}
      {loading && (
        <ActivityIndicator color={colors.primary} style={styles.spinner} />
      )}
    </View>
  );
}

function relativeTime(ts: number): string {
  const diff = Math.floor((Date.now() - ts) / 1000);
  if (diff >= 86400) return `${Math.floor(diff / 86400)}d ago`;
  if (diff >= 3600) return `${Math.floor(diff / 3600)}h ago`;
  if (diff >= 60) return `${Math.floor(diff / 60)}m ago`;
  return `${diff}s ago`;
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    marginBottom: 8,
  },
  iconBadge: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerText: {
    flex: 1,
    gap: 2,
  },
  cardTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textDark,
  },
  timestamp: {
    fontSize: 13,
    color: colors.gray,
  },
  expiredBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  expiredText: {
    fontSize: 12,
    fontWeight: '500',
    color: '#FF9500',
  },
  credentialText: {
    fontSize: 15,
    fontWeight: '500',
    color: colors.textDark,
    marginBottom: 4,
  },
  messageText: {
    fontSize: 14,
    color: colors.textDark,
    paddingVertical: 8,
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 12,
    marginTop: 12,
  },
  btn: {
    flex: 1,
    flexDirection: 'row',
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  btnDeny: {
    backgroundColor: colors.error,
  },
  btnApprove: {
    backgroundColor: colors.success,
  },
  btnText: {
    color: colors.white,
    fontWeight: '600',
    fontSize: 14,
  },
  challengeBody: {
    alignItems: 'center',
    marginTop: 4,
  },
  challengePrompt: {
    fontSize: 15,
    color: colors.gray,
    textAlign: 'center',
    marginVertical: 12,
  },
  numbersRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 16,
    marginBottom: 8,
  },
  numberCircle: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 2,
    borderColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  numberText: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
  },
  cancelBtn: {
    borderWidth: 1,
    borderColor: colors.error,
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 24,
    marginTop: 16,
    width: '100%',
    alignItems: 'center',
  },
  cancelText: {
    fontSize: 14,
    fontWeight: '500',
    color: colors.error,
  },
  spinner: {
    marginTop: 8,
  },
});
