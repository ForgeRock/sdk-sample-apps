/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { StyleSheet } from 'react-native';
import { colors } from './colors';

/**
 * Style tokens for the DaVinci sample screen and its organisms.
 */
export const davinciScreenStyles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 16,
    paddingBottom: 40,
  },
  panel: {
    width: '100%',
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10,
  },
  emptyText: {
    color: colors.gray,
    fontSize: 13,
    lineHeight: 18,
    marginTop: 6,
  },
  formSpacer: {
    height: 8,
  },
  blockingNote: {
    color: colors.error,
    fontSize: 13,
    lineHeight: 18,
    marginTop: 6,
  },
  successCard: {
    paddingVertical: 8,
  },
  successTitle: {
    color: colors.success,
    fontSize: 18,
    fontWeight: '700',
    marginBottom: 6,
  },
  successText: {
    color: colors.textDark,
    fontSize: 14,
    lineHeight: 20,
    marginBottom: 12,
  },
  errorCard: {
    borderWidth: 1,
    borderColor: colors.warningBorder,
    borderRadius: 10,
    backgroundColor: colors.warningBackgroundCard,
    padding: 12,
    marginBottom: 12,
  },
  errorCardTitle: {
    color: colors.warningText,
    fontWeight: '700',
    fontSize: 14,
    marginBottom: 4,
  },
  errorCardMessage: {
    color: colors.warningText,
    fontSize: 13,
    lineHeight: 18,
  },
  disabledButton: {
    opacity: 0.55,
  },
});

/**
 * Style tokens for individual DaVinci collector field renderers.
 */
export const davinciFieldStyles = StyleSheet.create({
  card: {
    marginBottom: 12,
  },
  fieldLabel: {
    color: colors.textDark,
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 6,
  },
  required: {
    color: colors.primary,
  },
  helperText: {
    color: colors.gray,
    fontSize: 12,
    marginTop: 4,
  },
  errorText: {
    color: colors.error,
    fontSize: 12,
    marginTop: 4,
  },
  labelContent: {
    color: colors.textDark,
    fontSize: 14,
    lineHeight: 20,
  },
  optionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: colors.journeyChoiceBorder,
    borderRadius: 8,
    marginBottom: 8,
  },
  optionRowSelected: {
    borderColor: colors.primary,
    backgroundColor: colors.selectedOptionBackground,
  },
  optionRowText: {
    color: colors.textDark,
    fontSize: 14,
    flex: 1,
  },
  optionRowTextSelected: {
    color: colors.primary,
    fontWeight: '600',
  },
  optionRadio: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 2,
    borderColor: colors.journeyChoiceBorder,
    marginRight: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optionRadioSelected: {
    borderColor: colors.primary,
  },
  optionRadioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.primary,
  },
  optionCheckbox: {
    width: 18,
    height: 18,
    borderRadius: 4,
    borderWidth: 2,
    borderColor: colors.journeyChoiceBorder,
    marginRight: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  optionCheckboxSelected: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  phoneRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  phoneCountry: {
    width: 90,
  },
  phoneNumber: {
    flex: 1,
  },
  deviceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 12,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    marginBottom: 8,
    backgroundColor: colors.surface,
  },
  deviceCardSelected: {
    borderColor: colors.primary,
    backgroundColor: colors.selectedOptionBackground,
  },
  deviceIcon: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  deviceInfo: {
    flex: 1,
  },
  deviceTitle: {
    color: colors.textDark,
    fontSize: 14,
    fontWeight: '600',
  },
  deviceDescription: {
    color: colors.gray,
    fontSize: 12,
    marginTop: 2,
  },
  passwordRequirementsCard: {
    backgroundColor: colors.messageBlockBackground,
    borderColor: colors.messageBlockBorder,
    borderWidth: 1,
    borderRadius: 8,
    padding: 10,
    marginTop: 8,
    marginBottom: 8,
  },
  passwordRequirementsTitle: {
    color: colors.messageBlockTitle,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 6,
  },
  passwordRequirementsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 2,
  },
  passwordRequirementsIcon: {
    marginRight: 6,
  },
  passwordRequirementsText: {
    color: colors.messageBlockText,
    fontSize: 12,
  },
  pickerTrigger: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1.5,
    borderColor: colors.inputInactiveBorder,
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 14,
    minHeight: 56,
    backgroundColor: colors.surface,
  },
  pickerTriggerText: {
    flex: 1,
    color: colors.inputText,
    fontSize: 16,
  },
  pickerTriggerPlaceholder: {
    flex: 1,
    color: colors.inputPlaceholder,
    fontSize: 16,
  },
  pickerChevron: {
    marginLeft: 8,
  },
  pickerOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.4)',
    justifyContent: 'flex-end',
  },
  pickerSheet: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    paddingTop: 8,
    paddingBottom: 24,
    maxHeight: '60%',
  },
  pickerSheetHandle: {
    width: 36,
    height: 4,
    borderRadius: 2,
    backgroundColor: colors.border,
    alignSelf: 'center',
    marginBottom: 12,
  },
  pickerSheetTitle: {
    color: colors.textDark,
    fontSize: 16,
    fontWeight: '700',
    paddingHorizontal: 16,
    paddingBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  pickerOption: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  pickerOptionSelected: {
    backgroundColor: colors.selectedOptionBackground,
  },
  pickerOptionText: {
    color: colors.textDark,
    fontSize: 15,
    flex: 1,
  },
  pickerOptionTextSelected: {
    color: colors.primary,
    fontWeight: '600',
  },
  unsupportedCard: {
    borderWidth: 1,
    borderColor: colors.warningBorder,
    borderRadius: 8,
    backgroundColor: colors.warningBackgroundSoft,
    padding: 10,
    marginBottom: 10,
  },
  unsupportedText: {
    color: colors.warningText,
    fontSize: 13,
  },
  flowLink: {
    paddingVertical: 8,
    alignItems: 'center',
  },
  flowLinkText: {
    color: colors.primary,
    fontSize: 14,
    fontWeight: '600',
    textDecorationLine: 'underline',
  },
  qrCodeImage: {
    width: 220,
    height: 220,
    alignSelf: 'center',
  },
  pollingStatusRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  pollingStatusText: {
    color: colors.gray,
    fontSize: 13,
    marginLeft: 8,
  },
});
