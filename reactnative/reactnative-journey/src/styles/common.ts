/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { StyleSheet, Platform } from 'react-native';
import { colors } from './colors';

/**
 * Shared control tokens used by interactive inputs.
 */
export const commonControlTokens = {
  primarySwitchTrackColor: {
    false: colors.border,
    true: colors.primary,
  },
} as const;

export const commonStyles = StyleSheet.create({
  // ===== Base Containers =====
  container: {
    flexGrow: 1,
    backgroundColor: colors.background,
    padding: 16,
    alignItems: 'center',
  },

  card: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    width: '100%',
    padding: 20,
    marginBottom: 20,
    shadowColor: colors.black,
    shadowOpacity: 0.04,
    shadowRadius: 1,
    elevation: 1,
  },

  // ===== Inputs =====
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: 10,
    fontSize: 14,
    backgroundColor: colors.surface,
  },
  inputLabel: {
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 6,
    color: colors.textDark,
  },

  // ===== Buttons =====
  buttonPrimary: {
    backgroundColor: colors.primary,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  buttonSecondary: {
    backgroundColor: colors.surface,
    borderColor: colors.primary,
    borderWidth: 1,
    paddingVertical: 10,
    borderRadius: 8,
    alignItems: 'center',
    marginVertical: 6,
  },
  buttonDanger: {
    backgroundColor: colors.error,
    paddingVertical: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 6,
  },
  buttonText: {
    color: colors.white,
    fontWeight: '600',
    fontSize: 15,
  },
  buttonTextSecondary: {
    color: colors.primary,
    fontWeight: '600',
    fontSize: 15,
  },
  buttonGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    marginTop: 10,
  },
  buttonGridItem: {
    width: '48%',
    marginTop: 0,
    marginBottom: 10,
  },

  // ===== Text =====
  textSuccess: {
    color: colors.success,
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
    marginVertical: 10,
  },
  textError: {
    color: colors.error,
    textAlign: 'center',
    fontWeight: '500',
    marginVertical: 8,
  },

  // ===== Code / Debug Box =====
  codeBox: {
    width: '100%',
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 16,
    marginTop: 10,
  },
  codeTitle: {
    fontWeight: '700',
    fontSize: 16,
    marginBottom: 8,
    color: colors.textDark,
  },
  codeText: {
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 12,
    color: colors.codeText,
  },
  payloadScrollContainer: {
    width: '100%',
    maxHeight: 220,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.payloadBorder,
    backgroundColor: colors.payloadBackground,
    overflow: 'hidden',
  },
  payloadScroll: {
    width: '100%',
  },
  payloadScrollContent: {
    padding: 10,
  },

  // ===== Home Screen Extensions =====
  homeContainer: {
    flex: 1,
    backgroundColor: colors.homeBackground,
  },
  homeHeader: {
    width: '100%',
    backgroundColor: colors.primary,
    paddingTop: 44,
    paddingBottom: 24,
    alignItems: 'center',
  },
  homeHeaderLogo: {
    width: 120,
    height: 120,
    resizeMode: 'contain',
    marginBottom: 12,
    borderRadius: 8,
  },
  homeHeaderTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.white,
    letterSpacing: 0.5,
  },
  homeHeaderSubtitle: {
    marginTop: 2,
    fontSize: 14,
    color: colors.homeHeaderSubtitle,
  },
  homeBody: {
    flex: 1,
  },
  homeBodyContent: {
    paddingHorizontal: 14,
    paddingTop: 12,
    paddingBottom: 18,
  },
  homeSectionTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.homeSectionTitle,
    letterSpacing: 0.8,
    marginTop: 10,
    marginBottom: 8,
  },
  homeList: {
    width: '100%',
  },
  homeRow: {
    backgroundColor: colors.surface,
    width: '100%',
    alignSelf: 'center',
    borderColor: colors.homeRowBorder,
    borderWidth: 1.2,
    paddingVertical: 16,
    paddingHorizontal: 14,
    marginVertical: 6,
    borderRadius: 10,
    shadowColor: colors.black,
    shadowOpacity: 0.08,
    shadowRadius: 5,
    elevation: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  homeRowDisabled: {
    backgroundColor: colors.homeRowDisabledBackground,
    borderColor: colors.homeRowDisabledBorder,
    opacity: 1,
  },
  homeRowContent: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingRight: 10,
  },
  homeRowIconWrap: {
    width: 42,
    height: 42,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
  },
  homeRowTextStack: {
    flex: 1,
    flexDirection: 'column',
  },
  homeRowTitleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 6,
  },
  homeRowTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: colors.homeRowTitle,
  },
  homeRowTitleDisabled: {
    color: colors.homeRowDisabledTitle,
  },
  homeComingSoonBadge: {
    backgroundColor: colors.homeBadgeBackground,
    borderColor: colors.homeBadgeBorder,
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  homeComingSoonText: {
    color: colors.primary,
    fontSize: 9,
    fontWeight: '700',
    letterSpacing: 0.3,
  },
  homeRowSubtitle: {
    marginTop: 4,
    fontSize: 14,
    color: colors.homeRowSubtitle,
  },
  homeRowSubtitleDisabled: {
    color: colors.homeRowDisabledSubtitle,
  },
  homeRowText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.textDark,
  },
  homeRowChevron: {
    fontSize: 34,
    color: colors.homeChevron,
    lineHeight: 36,
  },
  homeRowChevronDisabled: {
    color: colors.homeRowDisabledChevron,
  },
  homeFooter: {
    marginTop: 16,
    paddingVertical: 12,
    alignItems: 'center',
    width: '100%',
  },
  homeFooterText: {
    fontSize: 13,
    color: colors.homeFooterText,
    textAlign: 'center',
    marginTop: 12,
  },
  homeFooterLabelRow: {
    width: '100%',
    marginTop: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  configScreen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  configScreenContent: {
    paddingHorizontal: 16,
    paddingTop: 20,
    paddingBottom: 28,
  },
  configSection: {
    marginBottom: 14,
  },
  configSectionTitle: {
    color: colors.primary,
    fontSize: 22,
    fontWeight: '600',
    marginBottom: 6,
  },
  configOptionRow: {
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 14,
    paddingBottom: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  configOptionTextBlock: {
    flex: 1,
    paddingRight: 10,
  },
  configOptionName: {
    color: colors.textDark,
    fontSize: 21,
    fontWeight: '500',
  },
  configOptionMeta: {
    color: colors.textDark,
    fontSize: 14,
    marginTop: 2,
  },
  deviceIdCard: {
    width: '100%',
    backgroundColor: colors.deviceIdCardBackground,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.deviceIdCardBorder,
    paddingHorizontal: 14,
    paddingTop: 14,
    paddingBottom: 12,
    shadowColor: colors.black,
    shadowOpacity: 0.06,
    shadowRadius: 3,
    elevation: 1,
  },
  deviceIdHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  deviceIdTitle: {
    marginLeft: 10,
    fontSize: 18,
    fontWeight: '600',
    color: colors.homeRowTitle,
  },
  deviceIdSecuredText: {
    marginLeft: 12,
    fontSize: 16,
    color: colors.brandGreen,
    fontWeight: '600',
  },
  deviceIdDivider: {
    marginTop: 12,
    marginBottom: 10,
    height: 1,
    backgroundColor: colors.brandRed,
  },
  deviceIdValueText: {
    color: colors.brandRed,
    fontSize: 16,
    lineHeight: 24,
    fontWeight: '500',
    flexWrap: 'wrap',
  },
  deviceIdErrorText: {
    color: colors.deviceIdError,
    fontSize: 14,
    lineHeight: 20,
  },
  deviceIdText: {
    marginTop: 3,
    fontSize: 11,
    color: colors.homeFooterText,
    textAlign: 'center',
    paddingHorizontal: 16,
  },

  // ===== User Profile Screen Styles =====
  userProfileContainer: {
    flex: 1,
    backgroundColor: colors.homeBackground,
  },
  userProfileTabs: {
    flexDirection: 'row',
    backgroundColor: colors.homeBackground,
    borderBottomWidth: 1,
    borderBottomColor: colors.tabDivider,
  },
  userProfileTab: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 14,
    borderBottomWidth: 3,
    borderBottomColor: 'transparent',
  },
  userProfileTabActive: {
    borderBottomColor: colors.primary,
  },
  userProfileTabText: {
    fontSize: 17,
    color: colors.tabText,
    fontWeight: '500',
  },
  userProfileTabTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
  userProfileBody: {
    flex: 1,
  },
  userProfileBodyContent: {
    padding: 16,
  },
  userProfileCard: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.userProfileCardBorder,
    padding: 16,
    shadowColor: colors.black,
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  userProfileLoadingCard: {
    backgroundColor: colors.surface,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.userProfileCardBorder,
    padding: 16,
    alignItems: 'center',
    gap: 8,
  },
  userProfileEmptyCard: {
    backgroundColor: colors.userProfileEmptyBackground,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.userProfileEmptyBorder,
    padding: 20,
    shadowColor: colors.black,
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  userProfileEmptyTitle: {
    fontSize: 18,
    color: colors.userProfileEmptyTitle,
    textAlign: 'center',
    fontWeight: '700',
    marginBottom: 8,
  },
  userProfileSubText: {
    fontSize: 16,
    color: colors.userProfileSubText,
    lineHeight: 24,
    marginBottom: 14,
  },
  userProfileErrorText: {
    marginTop: 10,
    color: colors.error,
    fontSize: 12,
    textAlign: 'center',
  },
  userProfileSection: {
    marginTop: 14,
  },
  userProfileSectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.userProfileSectionTitle,
    marginBottom: 8,
  },
  userProfileInfoLine: {
    fontSize: 18,
    color: colors.userProfileInfoLine,
    lineHeight: 30,
    marginBottom: 2,
  },
  userProfileTokenLabel: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.userProfileTokenLabel,
    marginTop: 10,
    marginBottom: 4,
  },
  userProfileCode: {
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    fontSize: 12,
    color: colors.userProfileCodeText,
  },
  // ===== Journey Screen Styles =====
  journeyContainer: {
    flexGrow: 1,
    backgroundColor: colors.background,
    paddingHorizontal: 20,
    paddingTop: 40,
    alignItems: 'center',
  },

  journeyCard: {
    backgroundColor: colors.surface,
    borderRadius: 16,
    width: '100%',
    paddingVertical: 24,
    paddingHorizontal: 20,
    marginBottom: 20,
    shadowColor: colors.black,
    shadowOpacity: 0.05,
    shadowRadius: 6,
    elevation: 3,
  },

  journeyTitle: {
    fontSize: 22,
    fontWeight: '700',
    color: colors.textDark,
    textAlign: 'center',
    marginBottom: 24,
  },

  journeySectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.textDark,
    marginBottom: 12,
  },

  journeyButtonPrimary: {
    backgroundColor: colors.primary,
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 12,
  },

  journeyButtonSecondary: {
    backgroundColor: colors.blue,
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
    marginTop: 12,
  },

  journeyButtonText: {
    color: colors.white,
    fontWeight: '600',
    fontSize: 16,
  },

  journeyInput: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    padding: 12,
    fontSize: 15,
    backgroundColor: colors.journeyInputBackground,
    marginBottom: 10,
  },

  journeyLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.textDark,
    marginBottom: 6,
  },

  suggestionContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 8,
    marginBottom: 16,
  },

  suggestionChip: {
    borderColor: colors.border,
    borderWidth: 1.5,
    borderRadius: 20,
    paddingVertical: 6,
    paddingHorizontal: 12,
    margin: 4,
  },

  suggestionText: {
    color: colors.textDark,
    fontSize: 14,
  },

  inputGroup: {
    marginBottom: 14,
  },

  suspendedBox: {
    borderRadius: 10,
    padding: 12,
    marginBottom: 16,
  },

  suspendedMessage: {
    color: colors.textDark,
    fontSize: 15,
    lineHeight: 20,
  },

  helperNote: {
    marginTop: 8,
    color: colors.gray,
    fontSize: 13,
    fontStyle: 'italic',
    lineHeight: 18,
  },

  textSmall: {
    fontSize: 12,
    color: colors.success,
    marginVertical: 6,
  },

  // ===== Screen / Section =====
  screen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: '600' as const,
    color: colors.textDark,
  },
  linkText: {
    color: colors.primary,
    fontSize: 14,
    fontWeight: '600' as const,
  },
  dangerText: {
    color: colors.error,
    fontSize: 14,
    fontWeight: '600' as const,
  },
  metaLabel: {
    fontSize: 12,
    color: colors.gray,
    marginBottom: 2,
  },
  metaValue: {
    fontSize: 13,
    fontWeight: '500' as const,
  },

  // ===== Segmented Control =====
  segmentWrapper: {
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  segment: {
    flexDirection: 'row' as const,
    backgroundColor: colors.border,
    borderRadius: 8,
    padding: 2,
  },
  segmentTab: {
    flex: 1,
    paddingVertical: 8,
    alignItems: 'center' as const,
    borderRadius: 6,
  },
  segmentTabActive: {
    backgroundColor: colors.white,
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  segmentText: {
    fontSize: 14,
    fontWeight: '500' as const,
    color: colors.gray,
  },
  segmentTextActive: {
    color: colors.textDark,
    fontWeight: '600' as const,
  },

  // ===== Empty State =====
  emptyState: {
    alignItems: 'center' as const,
    paddingVertical: 48,
    gap: 12,
  },
  emptyIcon: {
    fontSize: 48,
    opacity: 0.4,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: '700' as const,
    color: colors.textDark,
  },
  emptySubtitle: {
    fontSize: 14,
    color: colors.gray,
    textAlign: 'center' as const,
    paddingHorizontal: 24,
  },

  // ===== Device Management Screen Styles =====
  deviceContainer: {
    flex: 1,
    backgroundColor: colors.background,
  },
  deviceContentContainer: {
    padding: 8,
  },
  deviceFilterCard: {
    backgroundColor: colors.surface,
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    elevation: 4,
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  deviceFilterTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: colors.textDark,
    marginBottom: 8,
  },
  deviceRadioRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
  },
  deviceRadioOuter: {
    width: 20,
    height: 20,
    borderRadius: 10,
    borderWidth: 2,
    borderColor: colors.gray,
    justifyContent: 'center',
    alignItems: 'center',
  },
  deviceRadioOuterSelected: {
    borderColor: colors.primary,
  },
  deviceRadioInner: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: colors.primary,
  },
  deviceRadioLabel: {
    fontSize: 15,
    color: colors.textDark,
    marginLeft: 8,
  },
  deviceListCard: {
    backgroundColor: colors.surface,
    borderRadius: 8,
    padding: 12,
    elevation: 4,
    shadowColor: colors.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  deviceListHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  deviceListTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: colors.textDark,
    flex: 1,
  },
  deviceRefreshButton: {
    padding: 4,
  },
  deviceLoadingContainer: {
    paddingVertical: 24,
    alignItems: 'center',
  },
  deviceErrorText: {
    color: colors.error,
    fontSize: 14,
    padding: 16,
  },
  deviceEmptyText: {
    color: colors.gray,
    fontSize: 14,
    padding: 16,
  },
  deviceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 4,
  },
  deviceRowName: {
    fontSize: 15,
    color: colors.textDark,
    flex: 1,
  },
  deviceRowSubtitle: {
    fontSize: 12,
    color: colors.gray,
    marginTop: 2,
  },
  deviceIconButton: {
    padding: 8,
  },
  deviceSeparator: {
    height: 1,
    backgroundColor: colors.border,
    marginHorizontal: 4,
  },
  deviceModalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  deviceModalCard: {
    width: '85%',
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 20,
  },
  deviceModalTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.textDark,
    marginBottom: 8,
  },
  deviceModalCurrentName: {
    fontSize: 14,
    color: colors.gray,
    marginBottom: 12,
  },
  deviceModalInput: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 4,
    padding: 10,
    fontSize: 15,
    color: colors.textDark,
  },
  deviceModalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 16,
    gap: 12,
  },
  deviceModalButton: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 4,
  },
  deviceModalButtonText: {
    fontSize: 14,
    color: colors.textDark,
  },
  deviceModalButtonPrimary: {
    backgroundColor: colors.primary,
  },
  deviceModalButtonPrimaryText: {
    fontSize: 14,
    color: colors.surface,
    fontWeight: '600',
  },
  deviceModalButtonDisabled: {
    opacity: 0.5,
  },
});
