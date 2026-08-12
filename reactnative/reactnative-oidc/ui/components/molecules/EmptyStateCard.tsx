/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import { commonStyles } from '../../../src/styles/common';
import AsyncActionButton from './AsyncActionButton';

/**
 * Props for the reusable empty state card.
 */
export type EmptyStateCardProps = {
  /**
   * Empty state title text.
   */
  title: string;
  /**
   * Empty state description text.
   */
  message: string;
  /**
   * Optional CTA label.
   */
  ctaLabel?: string;
  /**
   * Optional CTA handler.
   */
  onCtaPress?: () => void;
  /**
   * Optional error text shown below the message/CTA.
   */
  errorMessage?: string | null;
};

/**
 * Renders a reusable empty state card with optional call-to-action.
 *
 * @param props Empty state card props.
 * @returns Empty state card element.
 */
export default function EmptyStateCard(
  props: EmptyStateCardProps,
): React.ReactElement {
  const { title, message, ctaLabel, onCtaPress, errorMessage } = props;

  return (
    <View style={commonStyles.userProfileEmptyCard}>
      <Text style={commonStyles.userProfileEmptyTitle}>{title}</Text>
      <Text style={commonStyles.userProfileSubText}>{message}</Text>
      {ctaLabel && onCtaPress ? (
        <AsyncActionButton label={ctaLabel} onPress={onCtaPress} />
      ) : null}
      {errorMessage ? (
        <Text style={commonStyles.userProfileErrorText}>{errorMessage}</Text>
      ) : null}
    </View>
  );
}
