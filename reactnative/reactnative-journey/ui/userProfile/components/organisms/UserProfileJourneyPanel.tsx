/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ActivityIndicator, Text, View } from 'react-native';
import { type JourneyUserSession } from '@ping-identity/rn-journey';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';
import EmptyStateCard from '../../../components/molecules/EmptyStateCard';
import UserProfileInfoCard from '../molecules/UserProfileInfoCard';

/**
 * Props for the Journey profile tab panel.
 */
type UserProfileJourneyPanelProps = {
  /**
   * Whether Journey session state is loading.
   */
  loading: boolean;
  /**
   * Current Journey session.
   */
  session: JourneyUserSession | null;
  /**
   * Journey tab error message.
   */
  error: string | null;
  /**
   * Whether raw user info is shown.
   */
  showRawUserInfo: boolean;
  /**
   * Toggle raw user info visibility.
   */
  onToggleRawUserInfo: () => void;
  /**
   * Starts Journey login flow.
   */
  onStartJourney: () => void;
};

/**
 * Renders the Journey user profile tab body.
 *
 * @param props - Journey profile panel props.
 * @returns Journey profile panel element.
 */
export default function UserProfileJourneyPanel(
  props: UserProfileJourneyPanelProps,
): React.ReactElement {
  const {
    loading,
    session,
    error,
    showRawUserInfo,
    onToggleRawUserInfo,
    onStartJourney,
  } = props;

  if (loading) {
    return (
      <View style={commonStyles.userProfileLoadingCard}>
        <ActivityIndicator size="small" color={colors.primary} />
        <Text style={commonStyles.userProfileSubText}>
          Checking Journey session...
        </Text>
      </View>
    );
  }

  if (!session) {
    return (
      <EmptyStateCard
        title="No Journey User"
        message="Please authenticate using Journey to view user profile information."
        ctaLabel="Start Journey"
        onCtaPress={onStartJourney}
        errorMessage={error}
      />
    );
  }

  return (
    <UserProfileInfoCard
      title="Journey User Info"
      userInfo={(session.userInfo ?? null) as Record<string, unknown> | null}
      showRawUserInfo={showRawUserInfo}
      onToggleRawUserInfo={onToggleRawUserInfo}
    />
  );
}
