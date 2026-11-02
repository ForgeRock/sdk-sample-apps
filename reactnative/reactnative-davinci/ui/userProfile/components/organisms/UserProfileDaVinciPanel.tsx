/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ActivityIndicator, Text, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';
import EmptyStateCard from '../../../components/molecules/EmptyStateCard';
import UserProfileInfoCard from '../molecules/UserProfileInfoCard';

/**
 * Props for the DaVinci user profile tab panel.
 */
type UserProfileDaVinciPanelProps = {
  /**
   * Whether DaVinci session state is loading.
   */
  loading: boolean;
  /**
   * Current DaVinci userinfo payload.
   */
  userInfo: Record<string, unknown> | null;
  /**
   * Whether a DaVinci session exists.
   */
  hasSession: boolean;
  /**
   * DaVinci tab error message.
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
   * Navigate to DaVinci login flow.
   */
  onStartDaVinci: () => void;
};

/**
 * Renders the DaVinci user profile tab body.
 *
 * @param props - DaVinci profile panel props.
 * @returns DaVinci profile panel element.
 */
export default function UserProfileDaVinciPanel(
  props: UserProfileDaVinciPanelProps,
): React.ReactElement {
  const {
    loading,
    userInfo,
    hasSession,
    error,
    showRawUserInfo,
    onToggleRawUserInfo,
    onStartDaVinci,
  } = props;

  if (loading) {
    return (
      <View style={commonStyles.userProfileLoadingCard}>
        <ActivityIndicator size="small" color={colors.primary} />
        <Text style={commonStyles.userProfileSubText}>
          Checking DaVinci session...
        </Text>
      </View>
    );
  }

  if (!hasSession) {
    return (
      <EmptyStateCard
        title="No DaVinci User"
        message="Please authenticate using DaVinci to view user profile information."
        ctaLabel="Start DaVinci"
        onCtaPress={onStartDaVinci}
        errorMessage={error}
      />
    );
  }

  return (
    <UserProfileInfoCard
      title="DaVinci User Info"
      userInfo={userInfo}
      showRawUserInfo={showRawUserInfo}
      onToggleRawUserInfo={onToggleRawUserInfo}
    />
  );
}
