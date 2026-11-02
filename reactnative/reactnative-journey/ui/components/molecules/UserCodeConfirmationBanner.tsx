/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import { commonStyles } from '../../../src/styles/common';

/**
 * Props for {@link UserCodeConfirmationBanner}.
 */
export type UserCodeConfirmationBannerProps = {
  /**
   * RFC 8628 `user_code` the approver should visually match against the code
   * shown on the requesting device before approving.
   */
  userCode: string;
  /**
   * Optional testID applied to the banner's root view.
   */
  testID?: string;
};

/**
 * Displays the device authorization `user_code` so the person approving a
 * device can confirm it matches the code shown on the requesting device
 * before completing the approval action.
 *
 * @param props - Banner props.
 * @returns User code confirmation banner element.
 */
export default function UserCodeConfirmationBanner({
  userCode,
  testID,
}: UserCodeConfirmationBannerProps): React.ReactElement {
  return (
    <View testID={testID}>
      <Text style={commonStyles.deviceCopyLabel}>Confirm Device Code</Text>
      <View style={commonStyles.deviceCopyValueRow}>
        <Text
          style={[
            commonStyles.deviceCopyValueText,
            commonStyles.deviceCopyValueCode,
          ]}
        >
          {userCode}
        </Text>
      </View>
    </View>
  );
}
