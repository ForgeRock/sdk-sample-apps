/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { StyleSheet } from 'react-native';
import { colors } from './colors';

/**
 * Shared styles for `JourneyRouteScreen`.
 *
 * @remarks
 * Used by route-level containers that wrap Journey sample composition.
 */
export const journeyRouteScreenStyles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 16,
    paddingBottom: 40,
  },
});

/**
 * Shared styles for `JourneyFullScreen`.
 *
 * @remarks
 * Applied to full-screen callback rendering views used in test/demo flows.
 */
export const journeyFullScreenStyles = StyleSheet.create({
  section: {
    marginBottom: 16,
  },
  callbackCard: {
    borderWidth: 1,
    borderColor: colors.journeyCallbackCardBorder,
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
  },
  callbackType: {
    fontSize: 17,
    fontWeight: '700',
    color: colors.journeyCallbackType,
    marginBottom: 4,
  },
  callbackLabel: {
    fontSize: 15,
    color: colors.journeyCallbackLabel,
    marginBottom: 8,
  },
  integrationText: {
    fontSize: 14,
    color: colors.journeyIntegrationText,
  },
  switchRow: {
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  switchLabel: {
    color: colors.journeyCallbackType,
    fontSize: 15,
    flex: 1,
    paddingRight: 12,
  },
  optionButton: {
    borderWidth: 1,
    borderColor: colors.journeyChoiceBorder,
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 12,
    marginBottom: 8,
  },
  optionButtonSelected: {
    backgroundColor: colors.journeyChoiceSelected,
    borderColor: colors.journeyChoiceSelected,
  },
  optionButtonText: {
    color: colors.journeyChoiceText,
    fontSize: 15,
    fontWeight: '500',
  },
  optionButtonTextSelected: {
    color: colors.white,
  },
  issueText: {
    color: colors.error,
    fontSize: 14,
    marginBottom: 6,
  },
  errorText: {
    color: colors.error,
    fontSize: 14,
  },
});

/**
 * Shared styles for `JourneyStartPanel`.
 *
 * @remarks
 * Used by journey-name suggestion chips and quick-start controls.
 */
export const journeyStartPanelStyles = StyleSheet.create({
  suggestionPanel: {
    marginTop: 8,
  },
  suggestionPanelTitle: {
    color: colors.textDark,
    fontSize: 13,
    fontWeight: '700',
    marginBottom: 6,
  },
  suggestionScroll: {
    marginBottom: 16,
  },
  suggestionScrollContent: {
    paddingRight: 4,
  },
  suggestionRowsContainer: {
    flexDirection: 'column',
    alignItems: 'flex-start',
  },
  suggestionRow: {
    flexDirection: 'row',
    flexWrap: 'nowrap',
  },
  usedSuggestionChip: {
    borderColor: colors.success,
    backgroundColor: colors.warningBackgroundSoft,
  },
  usedSuggestionText: {
    color: colors.success,
    fontWeight: '700',
  },
  usedBadgeText: {
    marginTop: 2,
    fontSize: 10,
    fontWeight: '700',
    color: colors.success,
    textAlign: 'center',
  },
  wrappedSuggestionContainer: {
    marginTop: 0,
    marginBottom: 10,
  },
});

/**
 * Shared styles for `JourneyDebugPanel`.
 *
 * @remarks
 * Includes scrolling payload card layout and debug action controls.
 */
export const journeyDebugPanelStyles = StyleSheet.create({
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  title: {
    color: colors.textDark,
    fontSize: 16,
    fontWeight: '700',
  },
  clearButton: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: colors.surface,
  },
  clearButtonText: {
    color: colors.textDark,
    fontSize: 12,
    fontWeight: '600',
  },
  emptyText: {
    color: colors.gray,
    fontSize: 13,
  },
  eventCard: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    padding: 10,
    marginTop: 8,
    backgroundColor: colors.journeyInputBackground,
  },
  eventTitle: {
    color: colors.textDark,
    fontWeight: '700',
    fontSize: 12,
    marginBottom: 6,
    flex: 1,
  },
  eventHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  copyButton: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    backgroundColor: colors.surface,
    marginBottom: 6,
  },
  copyButtonText: {
    color: colors.textDark,
    fontSize: 11,
    fontWeight: '600',
  },
  payloadScroll: {
    maxHeight: 120,
  },
});

/**
 * Shared styles for Journey client panel composition.
 *
 * @remarks
 * Covers callback panel, status sections, and action buttons.
 */
export const journeyClientPanelStyles = StyleSheet.create({
  container: {
    width: '100%',
  },
  panelTitle: {
    color: colors.textDark,
    fontSize: 18,
    fontWeight: '700',
  },
  sectionTitle: {
    color: colors.textDark,
    fontSize: 15,
    fontWeight: '700',
    marginBottom: 10,
  },
  topGap: {
    marginTop: 10,
  },
  blockingNote: {
    color: colors.error,
    fontSize: 13,
    lineHeight: 18,
    marginTop: 4,
  },
  autoPollingNote: {
    color: colors.gray,
    fontSize: 13,
    lineHeight: 18,
    marginTop: 8,
    marginBottom: 4,
  },
  successActionsContainer: {
    marginTop: 10,
  },
  issueCard: {
    borderWidth: 1,
    borderColor: colors.warningBorder,
    borderRadius: 8,
    padding: 10,
    marginBottom: 8,
    backgroundColor: colors.warningBackgroundCard,
  },
  issueCode: {
    color: colors.warningText,
    fontWeight: '700',
    marginBottom: 4,
  },
  issueMessage: {
    color: colors.warningText,
    fontSize: 13,
  },
  disabledButton: {
    opacity: 0.55,
  },
});

/**
 * Shared style tokens for Journey callback field renderers.
 *
 * @remarks
 * Used by text/password/choice/boolean and unsupported field renderers.
 */
export const journeyFieldRendererStyles = StyleSheet.create({
  card: {
    padding: 0,
    marginBottom: 10,
    backgroundColor: 'transparent',
  },
  promptText: {
    color: colors.gray,
    marginBottom: 8,
    fontSize: 13,
  },
  outputHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  outputIcon: {
    marginRight: 8,
  },
  outputPromptText: {
    color: colors.gray,
    fontSize: 13,
    flex: 1,
  },
  helperText: {
    color: colors.gray,
    marginBottom: 6,
    fontSize: 12,
  },
  contentText: {
    lineHeight: 18,
  },
  topGap: {
    marginTop: 10,
  },
  optionWrap: {
    marginBottom: 8,
  },
  dropdownTrigger: {
    minHeight: 44,
    borderWidth: 1.5,
    borderColor: colors.inputInactiveBorder,
    borderRadius: 8,
    backgroundColor: colors.surface,
    paddingHorizontal: 12,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  dropdownTriggerText: {
    color: colors.inputInactiveText,
    fontSize: 16,
    flex: 1,
    paddingRight: 10,
  },
  dropdownChevron: {
    color: colors.inputInactiveText,
    fontSize: 11,
    fontWeight: '700',
  },
  dropdownMenu: {
    marginTop: 8,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    backgroundColor: colors.surface,
    overflow: 'hidden',
  },
  dropdownMenuItem: {
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  dropdownMenuItemSelected: {
    backgroundColor: colors.selectedOptionBackground,
  },
  dropdownMenuItemText: {
    color: colors.inputInactiveText,
    fontSize: 15,
  },
  dropdownMenuItemTextSelected: {
    color: colors.primary,
    fontWeight: '700',
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  inputFlex: {
    flex: 1,
  },
  toggleButton: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 10,
    backgroundColor: colors.surface,
  },
  toggleButtonText: {
    color: colors.textDark,
    fontSize: 13,
    fontWeight: '600',
  },
  selectedOption: {
    borderColor: colors.primary,
    backgroundColor: colors.selectedOptionBackground,
  },
  providerButtonContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  providerIconContainer: {
    width: 28,
    height: 28,
    borderRadius: 4,
    alignItems: 'center' as const,
    justifyContent: 'center' as const,
  },
  warningCard: {
    borderWidth: 1,
    borderColor: colors.warningBorder,
    borderRadius: 10,
    backgroundColor: colors.warningBackgroundSoft,
    padding: 10,
    marginBottom: 10,
  },
  warningTitle: {
    color: colors.warningText,
    fontWeight: '700',
    marginBottom: 4,
  },
  warningText: {
    color: colors.warningText,
    fontSize: 13,
  },
  payloadScroll: {
    maxHeight: 160,
  },
});
