/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import CardSection from '../../../components/molecules/CardSection';

/**
 * Props for OIDC action controls.
 */
type OidcActionsCardProps = {
  /**
   * Whether an OIDC action is currently in progress.
   */
  loading: boolean;
  /**
   * Whether a user is currently authenticated.
   */
  isAuthenticated: boolean;
  /**
   * Starts OIDC browser authorization.
   */
  onAuthorize: () => void;
  /**
   * Resolves access token payload.
   */
  onToken: () => void;
  /**
   * Refreshes token payload.
   */
  onRefresh: () => void;
  /**
   * Resolves userinfo payload.
   */
  onUserinfo: () => void;
  /**
   * Revokes active token set.
   */
  onRevoke: () => void;
  /**
   * Logs out active user.
   */
  onLogout: () => void;
};

/**
 * Renders grouped OIDC action buttons.
 *
 * @param props Actions card props.
 * @returns OIDC actions card element.
 */
export default function OidcActionsCard(
  props: OidcActionsCardProps,
): React.ReactElement {
  const {
    loading,
    isAuthenticated,
    onAuthorize,
    onToken,
    onRefresh,
    onUserinfo,
    onRevoke,
    onLogout,
  } = props;

  return (
    <CardSection
      title="OIDC Actions"
      subtitle={
        !isAuthenticated
          ? 'Start authorization or restore a session.'
          : undefined
      }
    >
      <View style={commonStyles.buttonGrid}>
        <AsyncActionButton
          label={isAuthenticated ? 'Logout' : 'Authorize'}
          onPress={isAuthenticated ? onLogout : onAuthorize}
          loading={loading}
          style={commonStyles.buttonGridItem}
        />
        {isAuthenticated ? (
          <>
            <AsyncActionButton
              label="Token"
              onPress={onToken}
              loading={loading}
              style={commonStyles.buttonGridItem}
            />
            <AsyncActionButton
              label="Refresh"
              onPress={onRefresh}
              loading={loading}
              style={commonStyles.buttonGridItem}
            />
            <AsyncActionButton
              label="Userinfo"
              onPress={onUserinfo}
              loading={loading}
              style={commonStyles.buttonGridItem}
            />
            <AsyncActionButton
              label="Revoke"
              variant="secondary"
              onPress={onRevoke}
              loading={loading}
              style={commonStyles.buttonGridItem}
            />
          </>
        ) : null}
      </View>
    </CardSection>
  );
}
