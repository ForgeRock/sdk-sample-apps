/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { StyleSheet } from 'react-native';
import { colors } from './colors';

/**
 * Shared styles for `CardSection`.
 */
export const cardSectionStyles = StyleSheet.create({
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 8,
  },
  subtitle: {
    marginBottom: 10,
  },
});

/**
 * Shared styles for `LabeledSwitchRow`.
 */
export const labeledSwitchRowStyles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 6,
  },
  label: {
    marginBottom: 0,
  },
});

/**
 * Shared styles for `CollapsiblePayloadSection`.
 */
export const collapsiblePayloadSectionStyles = StyleSheet.create({
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  loadingIndicator: {
    marginLeft: 8,
  },
});

/**
 * Shared styles for `DeviceProfileScreen`.
 */
export const deviceProfileScreenStyles = StyleSheet.create({
  collectorList: {
    marginTop: 10,
  },
});

/**
 * Shared styles for `PingTextInput`.
 */
export const pingTextInputStyles = StyleSheet.create({
  container: {
    width: '100%',
    marginBottom: 12,
  },
  inputWrapper: {
    minHeight: 56,
    borderRadius: 8,
    backgroundColor: colors.surface,
    paddingHorizontal: 12,
    paddingVertical: 8,
    paddingRight: 12,
    flexDirection: 'row',
    alignItems: 'center',
  },
  label: {
    position: 'absolute',
    left: 14,
    top: 17,
    borderRadius: 4,
    fontFamily: 'Montserrat-Medium',
    fontWeight: '500',
  },
  input: {
    flex: 1,
    color: colors.inputText,
    fontSize: 16,
    paddingVertical: 0,
    minHeight: 22,
    textAlignVertical: 'center',
  },
  passwordToggle: {
    marginLeft: 8,
    paddingVertical: 6,
    paddingHorizontal: 4,
  },
});
