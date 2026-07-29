/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import PayloadViewer from '../../../components/atoms/PayloadViewer';

/**
 * Props for the user profile JSON block.
 */
type UserProfileJsonBlockProps = {
  /**
   * Section title.
   */
  title: string;
  /**
   * Payload to render as JSON.
   */
  payload: Record<string, unknown> | null;
};

/**
 * Renders a scrollable JSON payload block for user profile data.
 *
 * @param props - JSON block props.
 * @returns JSON block element.
 */
export default function UserProfileJsonBlock(
  props: UserProfileJsonBlockProps,
): React.ReactElement {
  const { title, payload } = props;

  return (
    <View style={commonStyles.userProfileSection}>
      <Text style={commonStyles.userProfileSectionTitle}>{title}</Text>
      {!payload ? (
        <Text style={commonStyles.userProfileSubText}>No data available.</Text>
      ) : (
        <PayloadViewer
          payload={JSON.stringify(payload, null, 2)}
          textStyle={commonStyles.userProfileCode}
        />
      )}
    </View>
  );
}
