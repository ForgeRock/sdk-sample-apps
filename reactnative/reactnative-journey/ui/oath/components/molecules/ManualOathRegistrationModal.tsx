/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  Text,
  TextInput,
  View,
} from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';

/**
 * Props for the manual OATH registration modal.
 */
type ManualOathRegistrationModalProps = {
  /**
   * Whether the modal is visible.
   */
  visible: boolean;
  /**
   * Called when the user cancels or closes the modal.
   */
  onDismiss: () => void;
  /**
   * Called with the constructed `otpauth://` URI when the user submits the form.
   *
   * @param uri - The constructed `otpauth://` URI.
   */
  onSubmit: (uri: string) => void;
};

type OathType = 'TOTP' | 'HOTP';
type OathAlgorithm = 'SHA1' | 'SHA256' | 'SHA512';

/**
 * Modal form for manually entering OATH credential details.
 *
 * Constructs an `otpauth://` URI from the form fields and passes it to
 * `onSubmit`. Supports both TOTP and HOTP credential types, algorithm
 * selection, digit count, and TOTP period.
 *
 * @param props - Modal visibility, dismiss, and submit handlers.
 * @returns Manual OATH registration modal element.
 */
export default function ManualOathRegistrationModal(
  props: ManualOathRegistrationModalProps,
): React.ReactElement {
  const { visible, onDismiss, onSubmit } = props;

  const [issuer, setIssuer] = useState('');
  const [account, setAccount] = useState('');
  const [secret, setSecret] = useState('');
  const [selectedType, setSelectedType] = useState<OathType>('TOTP');
  const [algorithm, setAlgorithm] = useState<OathAlgorithm>('SHA1');
  const [digits, setDigits] = useState<6 | 8>(6);
  const [period, setPeriod] = useState('30');

  const isSubmitDisabled =
    issuer.trim().length === 0 ||
    account.trim().length === 0 ||
    secret.trim().length === 0;

  const handleDismiss = () => {
    setIssuer('');
    setAccount('');
    setSecret('');
    setSelectedType('TOTP');
    setAlgorithm('SHA1');
    setDigits(6);
    setPeriod('30');
    onDismiss();
  };

  const handleSubmit = () => {
    const type = selectedType.toLowerCase();
    const label = `${issuer.trim()}:${account.trim()}`;
    const uri = [
      `otpauth://${type}/${encodeURIComponent(label)}`,
      `?secret=${secret.trim().toUpperCase().replace(/\s/g, '')}`,
      `&issuer=${encodeURIComponent(issuer.trim())}`,
      `&algorithm=${algorithm}`,
      `&digits=${digits}`,
      selectedType === 'TOTP' ? `&period=${period || '30'}` : '',
    ].join('');
    onSubmit(uri);
    handleDismiss();
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={handleDismiss}
    >
      <View style={commonStyles.deviceModalBackdrop}>
        <View
          style={[
            commonStyles.deviceModalCard,
            { width: '92%', maxHeight: '90%' },
          ]}
        >
          <Text style={commonStyles.deviceModalTitle}>
            Manual OATH Registration
          </Text>
          <ScrollView showsVerticalScrollIndicator={false}>
            {/* Issuer */}
            <Text style={styles.fieldLabel}>Issuer *</Text>
            <TextInput
              testID="manual-oath-issuer"
              style={commonStyles.deviceModalInput}
              placeholder="e.g. PingIdentity"
              placeholderTextColor={colors.inputPlaceholder}
              value={issuer}
              onChangeText={setIssuer}
            />

            {/* Account Name */}
            <Text style={[styles.fieldLabel, { marginTop: 12 }]}>
              Account Name *
            </Text>
            <TextInput
              testID="manual-oath-account"
              style={commonStyles.deviceModalInput}
              placeholder="e.g. user@example.com"
              placeholderTextColor={colors.inputPlaceholder}
              value={account}
              onChangeText={setAccount}
              autoCapitalize="none"
            />

            {/* Secret */}
            <Text style={[styles.fieldLabel, { marginTop: 12 }]}>
              Secret (Base32) *
            </Text>
            <TextInput
              testID="manual-oath-secret"
              style={commonStyles.deviceModalInput}
              placeholder="e.g. JBSWY3DPEHPK3PXP"
              placeholderTextColor={colors.inputPlaceholder}
              value={secret}
              onChangeText={setSecret}
              autoCapitalize="characters"
            />

            {/* Type */}
            <Text style={[styles.fieldLabel, { marginTop: 12 }]}>Type</Text>
            <View style={styles.toggleRow}>
              <Pressable
                testID="manual-oath-type-totp"
                style={[
                  styles.toggleButton,
                  selectedType === 'TOTP' && styles.toggleButtonActive,
                ]}
                onPress={() => setSelectedType('TOTP')}
              >
                <Text
                  style={[
                    styles.toggleButtonText,
                    selectedType === 'TOTP' && styles.toggleButtonTextActive,
                  ]}
                >
                  TOTP
                </Text>
              </Pressable>
              <Pressable
                testID="manual-oath-type-hotp"
                style={[
                  styles.toggleButton,
                  selectedType === 'HOTP' && styles.toggleButtonActive,
                ]}
                onPress={() => setSelectedType('HOTP')}
              >
                <Text
                  style={[
                    styles.toggleButtonText,
                    selectedType === 'HOTP' && styles.toggleButtonTextActive,
                  ]}
                >
                  HOTP
                </Text>
              </Pressable>
            </View>

            {/* Algorithm */}
            <Text style={[styles.fieldLabel, { marginTop: 12 }]}>
              Algorithm
            </Text>
            <View style={styles.toggleRow}>
              {(['SHA1', 'SHA256', 'SHA512'] as OathAlgorithm[]).map(alg => (
                <Pressable
                  key={alg}
                  testID={`manual-oath-alg-${alg.toLowerCase()}`}
                  style={[
                    styles.toggleButton,
                    algorithm === alg && styles.toggleButtonActive,
                  ]}
                  onPress={() => setAlgorithm(alg)}
                >
                  <Text
                    style={[
                      styles.toggleButtonText,
                      algorithm === alg && styles.toggleButtonTextActive,
                    ]}
                  >
                    {alg}
                  </Text>
                </Pressable>
              ))}
            </View>

            {/* Digits */}
            <Text style={[styles.fieldLabel, { marginTop: 12 }]}>Digits</Text>
            <View style={styles.toggleRow}>
              <Pressable
                testID="manual-oath-digits-6"
                style={[
                  styles.toggleButton,
                  digits === 6 && styles.toggleButtonActive,
                ]}
                onPress={() => setDigits(6)}
              >
                <Text
                  style={[
                    styles.toggleButtonText,
                    digits === 6 && styles.toggleButtonTextActive,
                  ]}
                >
                  6
                </Text>
              </Pressable>
              <Pressable
                testID="manual-oath-digits-8"
                style={[
                  styles.toggleButton,
                  digits === 8 && styles.toggleButtonActive,
                ]}
                onPress={() => setDigits(8)}
              >
                <Text
                  style={[
                    styles.toggleButtonText,
                    digits === 8 && styles.toggleButtonTextActive,
                  ]}
                >
                  8
                </Text>
              </Pressable>
            </View>

            {/* Period (TOTP only) */}
            {selectedType === 'TOTP' ? (
              <>
                <Text style={[styles.fieldLabel, { marginTop: 12 }]}>
                  Period (seconds)
                </Text>
                <TextInput
                  testID="manual-oath-period"
                  style={commonStyles.deviceModalInput}
                  placeholder="30"
                  placeholderTextColor={colors.inputPlaceholder}
                  value={period}
                  onChangeText={setPeriod}
                  keyboardType="number-pad"
                />
              </>
            ) : null}
          </ScrollView>

          <View style={commonStyles.deviceModalActions}>
            <Pressable
              testID="manual-oath-cancel"
              style={commonStyles.deviceModalButton}
              onPress={handleDismiss}
            >
              <Text style={commonStyles.deviceModalButtonText}>Cancel</Text>
            </Pressable>
            <Pressable
              testID="manual-oath-submit"
              style={[
                commonStyles.deviceModalButton,
                commonStyles.deviceModalButtonPrimary,
                isSubmitDisabled && commonStyles.deviceModalButtonDisabled,
              ]}
              onPress={handleSubmit}
              disabled={isSubmitDisabled}
            >
              <Text style={commonStyles.deviceModalButtonPrimaryText}>Add</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = {
  fieldLabel: {
    fontSize: 13,
    fontWeight: '600' as const,
    color: colors.textDark,
    marginBottom: 4,
  },
  toggleRow: {
    flexDirection: 'row' as const,
    gap: 8,
  },
  toggleButton: {
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  toggleButtonActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  toggleButtonText: {
    fontSize: 13,
    color: colors.textDark,
    fontWeight: '500' as const,
  },
  toggleButtonTextActive: {
    color: colors.white,
    fontWeight: '600' as const,
  },
};
