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
 * Props for the OIDC profile tab panel.
 */
type UserProfileOidcPanelProps = {
  /**
   * Whether OIDC session state is loading.
   */
  loading: boolean;
  /**
   * Current OIDC user info payload.
   */
  userInfo: Record<string, unknown> | null;
  /**
   * Whether an OIDC session exists.
   */
  hasSession: boolean;
  /**
   * OIDC tab error message.
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
   * Starts OIDC login flow.
   */
  onStartOidc: () => void;
};

/**
 * Renders the OIDC user profile tab body.
 *
 * @param props - OIDC profile panel props.
 * @returns OIDC profile panel element.
 */
export default function UserProfileOidcPanel(
  props: UserProfileOidcPanelProps,
): React.ReactElement {
  const {
    loading,
    userInfo,
    hasSession,
    error,
    showRawUserInfo,
    onToggleRawUserInfo,
    onStartOidc,
  } = props;

  if (loading) {
    return (
      <View style={commonStyles.userProfileLoadingCard}>
        <ActivityIndicator size="small" color={colors.primary} />
        <Text style={commonStyles.userProfileSubText}>
          Checking OIDC session...
        </Text>
      </View>
    );
  }

  if (!hasSession) {
    return (
      <EmptyStateCard
        title="No OIDC User"
        message="Please authenticate using OIDC to view user profile information."
        ctaLabel="Start OIDC"
        onCtaPress={onStartOidc}
        errorMessage={error}
      />
    );
  }

  return (
    <UserProfileInfoCard
      title="OIDC User Info"
      userInfo={userInfo}
      showRawUserInfo={showRawUserInfo}
      onToggleRawUserInfo={onToggleRawUserInfo}
    />
  );
}
