/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { StyleSheet } from 'react-native';

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
