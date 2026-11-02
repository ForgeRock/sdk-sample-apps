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

type Props = {
  loading: boolean;
  userInfo: Record<string, unknown> | null;
  error: string | null;
  showRawUserInfo: boolean;
  onToggleRawUserInfo: () => void;
  onStartAuthGrant: () => void;
};

/** Renders the Auth Grant user profile tab. */
export default function UserProfileAuthGrantPanel({
  loading,
  userInfo,
  error,
  showRawUserInfo,
  onToggleRawUserInfo,
  onStartAuthGrant,
}: Props): React.ReactElement {
  if (loading) {
    return (
      <View style={commonStyles.userProfileLoadingCard}>
        <ActivityIndicator size="small" color={colors.primary} />
        <Text style={commonStyles.userProfileSubText}>
          Checking Auth Grant session...
        </Text>
      </View>
    );
  }
  if (!userInfo) {
    return (
      <EmptyStateCard
        title="No Auth Grant User"
        message="Please authenticate using Device Authorization Grant to view user profile information."
        ctaLabel="Start Auth Grant"
        onCtaPress={onStartAuthGrant}
        errorMessage={error}
      />
    );
  }
  return (
    <UserProfileInfoCard
      title="Auth Grant User Info"
      userInfo={userInfo}
      showRawUserInfo={showRawUserInfo}
      onToggleRawUserInfo={onToggleRawUserInfo}
    />
  );
}
