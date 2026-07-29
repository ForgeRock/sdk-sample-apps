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
 * Props for token actions card.
 */
type TokenActionsCardProps = {
  /**
   * Whether actions are currently in progress.
   */
  loading: boolean;
  /**
   * Trigger access-token retrieval.
   */
  onAccessToken: () => void;
  /**
   * Trigger token refresh.
   */
  onRefresh: () => void;
  /**
   * Trigger token revoke.
   */
  onRevoke: () => void;
  /**
   * Clear currently displayed output.
   */
  onClear: () => void;
};

/**
 * Renders token action buttons.
 *
 * @param props - Actions card props.
 * @returns Token actions card element.
 */
export default function TokenActionsCard(
  props: TokenActionsCardProps,
): React.ReactElement {
  const { loading, onAccessToken, onRefresh, onRevoke, onClear } = props;

  return (
    <CardSection>
      <View style={commonStyles.buttonGrid}>
        <AsyncActionButton
          label="AccessToken"
          onPress={onAccessToken}
          loading={loading}
          style={commonStyles.buttonGridItem}
        />
        <AsyncActionButton
          label="Clear"
          variant="secondary"
          onPress={onClear}
          disabled={loading}
          style={commonStyles.buttonGridItem}
        />
        <AsyncActionButton
          label="Refresh"
          onPress={onRefresh}
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
      </View>
    </CardSection>
  );
}
