/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {
  Alert,
  Clipboard,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { OathCodeInfo, OathCredential } from '@ping-identity/rn-oath';
import { colors } from '../../../../src/styles/colors';
import OathCircularProgress from '../atoms/OathCircularProgress';

/**
 * Props for {@link OathAccountDetailModal}.
 */
type OathAccountDetailModalProps = {
  /** Whether the modal is visible. */
  visible: boolean;
  /** The credential to display, or `null` when no credential is selected. */
  credential: OathCredential | null;
  /** Latest code and timing metadata. */
  codeInfo: OathCodeInfo | undefined;
  /** Called when the user dismisses the modal (back button or backdrop). */
  onDismiss: () => void;
  /** Called when the user confirms deletion of the credential. */
  onDelete: () => void;
  /** Called when the user taps Generate for HOTP credentials. */
  onRefreshHotp: () => void;
};

/**
 * Maps an internal algorithm identifier to a display string.
 */
function algorithmLabel(alg: string | undefined): string {
  switch ((alg ?? '').toUpperCase()) {
    case 'SHA1':
      return 'SHA-1';
    case 'SHA256':
      return 'SHA-256';
    case 'SHA512':
      return 'SHA-512';
    default:
      return alg ?? 'SHA-1';
  }
}

/**
 * A row in the account-information section.
 */
function InfoRow({
  label,
  value,
}: {
  label: string;
  value: string;
}): React.ReactElement {
  return (
    <View style={infoStyles.row}>
      <Text style={infoStyles.label}>{label}</Text>
      <Text style={infoStyles.value}>{value}</Text>
    </View>
  );
}

/**
 * Bottom-sheet style modal showing full OATH account details.
 *
 * Mirrors the `OathAccountDetailView` sheet from the iOS PingExample app:
 *
 * - **Header** — gradient circle icon, issuer, account name.
 * - **Code section** — large circular countdown ring (TOTP) or generate button
 *   (HOTP), plus the current OTP code below it.
 * - **Account information** — type, algorithm, digits, and period/counter.
 * - **Delete button** at the bottom.
 *
 * @param props - Visibility, credential data, code info, and action handlers.
 * @returns Account detail modal element.
 */
export default function OathAccountDetailModal(
  props: OathAccountDetailModalProps,
): React.ReactElement | null {
  const { visible, credential, codeInfo, onDismiss, onDelete, onRefreshHotp } =
    props;

  if (!credential) return null;

  const isLocked = credential.isLocked ?? false;
  const isTotp = credential.type === 'TOTP';
  const hasCode = codeInfo !== undefined && !isLocked;
  const timeRemaining = codeInfo?.timeRemaining ?? 0;
  const progress = codeInfo?.progress ?? 0;

  const formatCode = (code: string): string => {
    if (code.length <= 4) return code;
    const mid = Math.floor(code.length / 2);
    return `${code.slice(0, mid)} ${code.slice(mid)}`;
  };

  const displayCode = hasCode ? formatCode(codeInfo.code) : '------';

  const handleCopy = () => {
    if (!hasCode) return;
    Clipboard.setString(codeInfo.code);
  };

  const handleDeletePress = () => {
    Alert.alert(
      'Delete Account',
      'Are you sure you want to delete this account? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Delete', style: 'destructive', onPress: onDelete },
      ],
    );
  };

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onDismiss}
    >
      <View style={styles.container}>
        {/* Navigation bar */}
        <View style={styles.navBar}>
          <Pressable
            testID="oath-detail-close"
            onPress={onDismiss}
            hitSlop={12}
          >
            <MaterialIcon name="close" size={24} color={colors.textDark} />
          </Pressable>
          <Text style={styles.navTitle}>Account Details</Text>
          <Pressable
            testID="oath-detail-copy"
            onPress={handleCopy}
            disabled={!hasCode}
            hitSlop={12}
          >
            <MaterialIcon
              name="content-copy"
              size={22}
              color={hasCode ? colors.primary : colors.gray}
            />
          </Pressable>
        </View>

        <ScrollView
          contentContainerStyle={styles.scrollContent}
          showsVerticalScrollIndicator={false}
        >
          {/* ── Header ── */}
          <View style={styles.header}>
            <View style={styles.headerIcon}>
              <MaterialIcon
                name={isTotp ? 'schedule' : 'tag'}
                size={40}
                color={colors.white}
              />
            </View>
            <Text style={styles.headerIssuer}>
              {credential.displayIssuer || credential.issuer}
            </Text>
            <Text style={styles.headerAccount}>
              {credential.displayAccountName || credential.accountName}
            </Text>
          </View>

          {/* ── Code section ── */}
          <View style={styles.section}>
            {isTotp ? (
              <OathCircularProgress
                progress={progress}
                timeRemaining={timeRemaining}
                size={120}
                strokeWidth={8}
                locked={isLocked}
              />
            ) : null}

            {isLocked ? (
              <View style={styles.lockedCodeBlock}>
                <Text style={styles.lockedCodeText}>{'------'}</Text>
                <Text style={styles.lockedSubText}>Account is locked</Text>
              </View>
            ) : (
              <Text style={styles.codeText}>{displayCode}</Text>
            )}

            {!isLocked && !isTotp ? (
              <Pressable
                testID="oath-detail-generate"
                style={styles.generateButton}
                onPress={onRefreshHotp}
              >
                <MaterialIcon name="refresh" size={20} color={colors.white} />
                <Text style={styles.generateButtonText}>Generate New Code</Text>
              </Pressable>
            ) : null}
          </View>

          {/* ── Account information ── */}
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Account Information</Text>
            <InfoRow
              label="Type"
              value={isTotp ? 'TOTP (Time-based)' : 'HOTP (Counter-based)'}
            />
            <View style={styles.rowDivider} />
            <InfoRow
              label="Algorithm"
              value={algorithmLabel(credential.algorithm)}
            />
            <View style={styles.rowDivider} />
            <InfoRow label="Digits" value={String(credential.digits)} />
            <View style={styles.rowDivider} />
            {isTotp ? (
              <InfoRow
                label="Period"
                value={`${credential.period ?? 30} seconds`}
              />
            ) : (
              <InfoRow
                label="Counter"
                value={String(codeInfo?.counter ?? credential.counter ?? 0)}
              />
            )}
          </View>

          {/* ── Delete button ── */}
          <Pressable
            testID="oath-detail-delete"
            style={styles.deleteButton}
            onPress={handleDeletePress}
          >
            <MaterialIcon name="delete" size={20} color={colors.white} />
            <Text style={styles.deleteButtonText}>Delete Account</Text>
          </Pressable>
        </ScrollView>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  navBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingTop: 16,
    paddingBottom: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: colors.border,
    backgroundColor: colors.surface,
  },
  navTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.textDark,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 24,
    paddingBottom: 40,
    gap: 16,
  },
  // Header
  header: {
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
  },
  headerIcon: {
    width: 100,
    height: 100,
    borderRadius: 50,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 4,
  },
  headerIssuer: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.textDark,
    textAlign: 'center',
  },
  headerAccount: {
    fontSize: 15,
    color: colors.gray,
    textAlign: 'center',
  },
  // Section card
  section: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 20,
    alignItems: 'center',
    gap: 16,
  },
  sectionTitle: {
    alignSelf: 'flex-start',
    fontSize: 16,
    fontWeight: '600',
    color: colors.textDark,
    marginBottom: 4,
  },
  // Code display
  codeText: {
    fontFamily: 'monospace',
    fontSize: 40,
    fontWeight: '700',
    color: colors.primary,
    letterSpacing: 4,
  },
  lockedCodeBlock: {
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.background,
    borderRadius: 12,
    paddingHorizontal: 24,
    paddingVertical: 16,
  },
  lockedCodeText: {
    fontFamily: 'monospace',
    fontSize: 40,
    fontWeight: '700',
    color: colors.gray,
    letterSpacing: 4,
  },
  lockedSubText: {
    fontSize: 13,
    color: colors.gray,
  },
  // Generate button (HOTP)
  generateButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: colors.primary,
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 24,
    alignSelf: 'stretch',
  },
  generateButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '600',
  },
  // Info rows
  rowDivider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.border,
    alignSelf: 'stretch',
    marginLeft: 90,
  },
  // Delete button
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: colors.error,
    borderRadius: 12,
    paddingVertical: 14,
    marginTop: 8,
  },
  deleteButtonText: {
    color: colors.white,
    fontSize: 16,
    fontWeight: '600',
  },
});

const infoStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    alignSelf: 'stretch',
  },
  label: {
    width: 90,
    fontSize: 13,
    color: colors.gray,
  },
  value: {
    flex: 1,
    fontSize: 13,
    fontWeight: '500',
    color: colors.textDark,
  },
});
