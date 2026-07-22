/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {
  Clipboard,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { OathCodeInfo, OathCredential } from '@ping-identity/rn-oath';
import { colors } from '../../../../src/styles/colors';
import OathCircularProgress from '../atoms/OathCircularProgress';

/**
 * Props for {@link OathCredentialCard}.
 */
type OathCredentialCardProps = {
  /** The OATH credential to display. */
  credential: OathCredential;
  /** Latest code and timing metadata, or `undefined` when not yet available. */
  codeInfo: OathCodeInfo | undefined;
  /** Called when the card is tapped to open the detail view. */
  onPress: () => void;
  /** Called when the user taps Generate for HOTP credentials. */
  onRefreshHotp: () => void;
};

/**
 * iOS-style OATH credential card.
 *
 * Layout mirrors `OathAccountCardView` from the iOS PingExample app:
 * - Top row: gradient icon square (with optional lock badge), issuer + account
 *   name, and a circular countdown ring (TOTP) or generate button (HOTP) on
 *   the trailing edge.
 * - Divider.
 * - Bottom row: large monospaced OTP code and a copy button.
 *
 * The whole card is tappable and calls `onPress` to open the detail modal.
 *
 * @param props - Credential data, code metadata, and action handlers.
 * @returns Credential card element.
 *
 * @remarks
 * Locked credentials show `"------"` in place of the code and render a
 * muted red ring instead of the countdown ring.
 */
export default function OathCredentialCard(
  props: OathCredentialCardProps,
): React.ReactElement {
  const { credential, codeInfo, onPress, onRefreshHotp } = props;

  const isLocked = credential.isLocked ?? false;
  const hasCode = codeInfo !== undefined && !isLocked;

  const formatCode = (code: string): string => {
    if (code.length <= 4) return code;
    const mid = Math.floor(code.length / 2);
    return `${code.slice(0, mid)} ${code.slice(mid)}`;
  };

  const displayCode = hasCode ? formatCode(codeInfo.code) : '------';
  const isTotp = credential.type === 'TOTP';
  const timeRemaining = codeInfo?.timeRemaining ?? 0;
  const progress = codeInfo?.progress ?? 0;

  const handleCopy = () => {
    if (!hasCode) return;
    Clipboard.setString(codeInfo.code);
  };

  return (
    <TouchableOpacity
      testID={`oath-credential-card-${credential.id}`}
      activeOpacity={0.85}
      onPress={onPress}
      style={styles.card}
    >
      {/* ── Top row ── */}
      <View style={styles.topRow}>
        {/* Icon with optional lock badge */}
        <View style={styles.iconWrapper}>
          <View style={styles.iconGradient}>
            <MaterialIcon
              name={isTotp ? 'schedule' : 'tag'}
              size={20}
              color={colors.white}
            />
          </View>
          {isLocked ? (
            <View style={styles.lockBadge}>
              <MaterialIcon name="lock" size={9} color={colors.white} />
            </View>
          ) : null}
        </View>

        {/* Issuer + account name */}
        <View style={styles.textBlock}>
          <Text style={styles.issuerText} numberOfLines={1}>
            {credential.displayIssuer || credential.issuer}
          </Text>
          <Text style={styles.accountText} numberOfLines={1}>
            {credential.displayAccountName || credential.accountName}
          </Text>
        </View>

        {/* Right: ring (TOTP) or generate button (HOTP) */}
        {isTotp ? (
          <OathCircularProgress
            progress={progress}
            timeRemaining={timeRemaining}
            size={40}
            strokeWidth={3}
            locked={isLocked}
          />
        ) : (
          <Pressable
            testID={`oath-hotp-refresh-${credential.id}`}
            onPress={e => {
              e.stopPropagation?.();
              onRefreshHotp();
            }}
            disabled={isLocked}
            hitSlop={8}
          >
            <MaterialIcon
              name="refresh"
              size={24}
              color={isLocked ? colors.gray : colors.primary}
            />
          </Pressable>
        )}
      </View>

      {/* ── Divider ── */}
      <View style={styles.divider} />

      {/* ── Bottom row: code + copy ── */}
      <View style={styles.bottomRow}>
        <Text style={[styles.codeText, isLocked && styles.codeTextLocked]}>
          {displayCode}
        </Text>
        <Pressable
          testID={`oath-copy-${credential.id}`}
          onPress={e => {
            e.stopPropagation?.();
            handleCopy();
          }}
          disabled={!hasCode}
          hitSlop={8}
        >
          <MaterialIcon
            name="content-copy"
            size={18}
            color={hasCode ? colors.primary : colors.gray}
          />
        </Pressable>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOpacity: 0.05,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  topRow: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    gap: 12,
  },
  iconWrapper: {
    position: 'relative',
  },
  iconGradient: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  lockBadge: {
    position: 'absolute',
    bottom: -3,
    right: -3,
    width: 16,
    height: 16,
    borderRadius: 8,
    backgroundColor: colors.error,
    alignItems: 'center',
    justifyContent: 'center',
  },
  textBlock: {
    flex: 1,
    gap: 2,
  },
  issuerText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textDark,
  },
  accountText: {
    fontSize: 13,
    color: colors.gray,
  },
  divider: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: colors.border,
    marginHorizontal: 16,
  },
  bottomRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  codeText: {
    fontFamily: 'monospace',
    fontSize: 28,
    fontWeight: '700',
    color: colors.primary,
    letterSpacing: 2,
  },
  codeTextLocked: {
    color: colors.gray,
  },
});
