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
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { usePush } from '@ping-identity/rn-push';
import type { PushCredential } from '@ping-identity/rn-push';
import { commonStyles } from '../../src/styles/common';
import { colors } from '../../src/styles/colors';
import QrScannerScreen from './QrScannerScreen';

/**
 * Manages enrolled push accounts (credentials).
 *
 * Shows the current FCM/APNs device token, lists all enrolled accounts, and lets
 * the user scan a `pushauth://` QR code to register a new account or remove an
 * existing one. Use as the "Push Authenticator" tab in an MFA flow.
 */
export default function PushScreen() {
  const [data, { loading, error, refresh }] = usePush();
  const [showScanner, setShowScanner] = useState(false);

  if (loading) {
    return (
      <View style={commonStyles.container}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (error) {
    return (
      <View style={commonStyles.container}>
        <Text style={commonStyles.textError}>{error.message}</Text>
      </View>
    );
  }

  if (!data) return null;
  const { client, credentials, deviceToken } = data;

  if (showScanner) {
    return (
      <QrScannerScreen
        pushClient={client}
        onSuccess={async () => {
          await refresh();
          setShowScanner(false);
        }}
        onCancel={() => setShowScanner(false)}
      />
    );
  }

  const canEnroll = Boolean(deviceToken);

  const deleteCredential = (credentialId: string) => {
    Alert.alert('Delete Account', 'Remove this push account?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: async () => {
          try {
            await client!.deleteCredential(credentialId);
            await refresh();
          } catch (err) {
            Alert.alert(
              'Delete Failed',
              err instanceof Error ? err.message : String(err),
            );
          }
        },
      },
    ]);
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      {/* Device Token */}
      <View style={commonStyles.card}>
        <View style={styles.tokenHeader}>
          <View style={styles.tokenTitleRow}>
            <Text style={commonStyles.sectionTitle}>Device Token</Text>
            <View
              style={[
                styles.statusDot,
                {
                  backgroundColor: deviceToken ? colors.success : colors.error,
                },
              ]}
            />
          </View>
          <View style={styles.tokenActions}>
            {Platform.OS === 'android' && !deviceToken && client && (
              <TouchableOpacity
                onPress={async () => {
                  try {
                    await client.refreshToken();
                    await refresh();
                  } catch (err) {
                    Alert.alert(
                      'Fetch Token Failed',
                      err instanceof Error ? err.message : String(err),
                    );
                  }
                }}
              >
                <Text style={commonStyles.linkText}>Fetch Token</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>
        {deviceToken ? (
          <Text style={styles.tokenText} numberOfLines={2}>
            {deviceToken}
          </Text>
        ) : (
          <Text style={commonStyles.userProfileSubText}>
            No device token registered
          </Text>
        )}
      </View>

      {/* Accounts */}
      {credentials.length === 0 ? (
        <View style={commonStyles.emptyState}>
          <MaterialIcon
            name="notifications"
            size={48}
            color={colors.gray}
            style={{ opacity: 0.4 }}
          />
          <Text style={commonStyles.emptyTitle}>No Push Accounts</Text>
          <Text style={commonStyles.emptySubtitle}>
            Scan a QR code to register your first push authentication account
          </Text>
          <TouchableOpacity
            style={[styles.scanButton, !canEnroll && styles.scanButtonDisabled]}
            onPress={() => canEnroll && setShowScanner(true)}
            disabled={!canEnroll}
          >
            <MaterialIcon
              name="qr-code-scanner"
              size={24}
              color={canEnroll ? colors.primary : colors.gray}
            />
            <Text
              style={[
                styles.scanButtonText,
                !canEnroll && styles.scanButtonTextDisabled,
              ]}
            >
              {canEnroll ? 'Scan QR Code' : 'Waiting for token…'}
            </Text>
          </TouchableOpacity>
        </View>
      ) : (
        <View style={styles.accountsList}>
          {credentials.map((cred: PushCredential) => (
            <View key={cred.id} style={commonStyles.card}>
              <View style={styles.accountRow}>
                <View
                  style={[
                    styles.accountIcon,
                    cred.isLocked && styles.accountIconLocked,
                  ]}
                >
                  <MaterialIcon
                    name={cred.isLocked ? 'lock' : 'notifications'}
                    size={20}
                    color={colors.white}
                  />
                </View>
                <View style={styles.accountInfo}>
                  <Text style={styles.accountIssuer}>
                    {cred.displayIssuer ?? cred.issuer}
                  </Text>
                  <Text style={styles.accountName}>
                    {cred.displayAccountName ?? cred.accountName}
                  </Text>
                </View>
                <View
                  style={[
                    styles.accountStatus,
                    cred.isLocked && styles.accountStatusLocked,
                  ]}
                >
                  <MaterialIcon
                    name={cred.isLocked ? 'lock' : 'check'}
                    size={16}
                    color={colors.white}
                  />
                </View>
              </View>

              {/* Meta row */}
              <View style={styles.accountMeta}>
                <View>
                  <Text style={commonStyles.metaLabel}>Status</Text>
                  <Text
                    style={[
                      commonStyles.metaValue,
                      { color: cred.isLocked ? colors.error : colors.success },
                    ]}
                  >
                    {cred.isLocked ? 'Locked' : 'Active'}
                  </Text>
                </View>
                <View>
                  <Text style={commonStyles.metaLabel}>Platform</Text>
                  <Text style={commonStyles.metaValue}>{cred.platform}</Text>
                </View>
                <View>
                  <Text style={commonStyles.metaLabel}>Enrolled</Text>
                  <Text style={commonStyles.metaValue}>
                    {new Date(cred.createdAt).toLocaleDateString()}
                  </Text>
                </View>
              </View>

              {/* Actions row */}
              <View style={styles.accountActions}>
                <TouchableOpacity onPress={() => deleteCredential(cred.id)}>
                  <Text style={commonStyles.dangerText}>Remove</Text>
                </TouchableOpacity>
              </View>
            </View>
          ))}
        </View>
      )}

      {credentials.length > 0 && (
        <TouchableOpacity
          style={[styles.fab, !canEnroll && styles.scanButtonDisabled]}
          onPress={() => canEnroll && setShowScanner(true)}
          disabled={!canEnroll}
        >
          <Text style={styles.fabText}>+</Text>
        </TouchableOpacity>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: colors.background,
    padding: 16,
    paddingBottom: 80,
    gap: 16,
  },
  tokenHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  tokenActions: {
    flexDirection: 'row',
    gap: 12,
  },
  tokenTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  statusDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
  },
  tokenText: {
    fontSize: 11,
    fontFamily: 'monospace',
    color: colors.gray,
    lineHeight: 16,
  },
  scanButton: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 140,
    height: 100,
    backgroundColor: colors.white,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    marginTop: 8,
    gap: 6,
  },
  scanButtonText: {
    fontSize: 14,
    fontWeight: '500',
    color: colors.primary,
  },
  scanButtonDisabled: {
    opacity: 0.5,
  },
  scanButtonTextDisabled: {
    color: colors.gray,
  },
  accountsList: {
    gap: 12,
  },
  accountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    marginBottom: 12,
  },
  accountIcon: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  accountIconLocked: {
    backgroundColor: colors.error,
  },
  accountInfo: {
    flex: 1,
    gap: 2,
  },
  accountIssuer: {
    fontSize: 15,
    fontWeight: '600',
    color: colors.textDark,
  },
  accountName: {
    fontSize: 13,
    color: colors.gray,
  },
  accountStatus: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.success,
    alignItems: 'center',
    justifyContent: 'center',
  },
  accountStatusLocked: {
    backgroundColor: colors.error,
  },
  accountMeta: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 12,
    paddingBottom: 12,
  },
  accountActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: 20,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 12,
  },
  fab: {
    position: 'absolute',
    bottom: 24,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    elevation: 4,
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  fabText: {
    color: colors.white,
    fontSize: 28,
    lineHeight: 32,
  },
});
