/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import KeyValueList, {
  type KeyValueItem,
} from '../../../components/atoms/KeyValueList';
import UserProfileJsonBlock from './UserProfileJsonBlock';

/**
 * Props for the user info presentation card.
 */
type UserProfileInfoCardProps = {
  /**
   * Source label shown in the card title.
   */
  title: string;
  /**
   * User info payload to render.
   */
  userInfo: Record<string, unknown> | null;
  /**
   * Whether raw payload should be shown.
   */
  showRawUserInfo: boolean;
  /**
   * Toggle raw payload visibility.
   */
  onToggleRawUserInfo: () => void;
};

/**
 * Converts an unknown profile field into a display value.
 *
 * @param value - Candidate profile field value.
 * @returns Display-safe value or `null` when unavailable.
 */
const asDisplayValue = (value: unknown): string | null => {
  if (typeof value === 'string' && value.trim().length > 0) {
    return value.trim();
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return null;
};

/**
 * Reads the first available profile key from a payload.
 *
 * @param payload - User info payload.
 * @param keys - Candidate keys in lookup order.
 * @returns Display string for the first matching key.
 */
const readProfileField = (
  payload: Record<string, unknown> | null,
  keys: readonly string[],
): string => {
  if (!payload) {
    return 'Not available';
  }
  for (const key of keys) {
    const value = asDisplayValue(payload[key]);
    if (value) {
      return value;
    }
  }
  return 'Not available';
};

/**
 * Adds quotes to values that are present.
 *
 * @param value - Display value.
 * @returns Quoted value when available.
 */
const wrapProfileValue = (value: string): string => {
  return value === 'Not available' ? value : `"${value}"`;
};

/**
 * Renders a shared user-info card for Journey and OIDC tabs.
 *
 * @param props - User info card props.
 * @returns User info card element.
 */
export default function UserProfileInfoCard(
  props: UserProfileInfoCardProps,
): React.ReactElement {
  const { title, userInfo, showRawUserInfo, onToggleRawUserInfo } = props;

  const firstName = wrapProfileValue(
    readProfileField(userInfo, ['given_name', 'firstName', 'first_name']),
  );
  const familyName = wrapProfileValue(
    readProfileField(userInfo, ['family_name', 'lastName', 'last_name']),
  );
  const email = wrapProfileValue(readProfileField(userInfo, ['email']));
  const infoItems: KeyValueItem[] = [
    { label: 'First name', value: firstName },
    { label: 'Family name', value: familyName },
    { label: 'Email', value: email },
  ];

  return (
    <View style={commonStyles.userProfileCard}>
      <Text style={commonStyles.userProfileSectionTitle}>{title}</Text>
      <KeyValueList
        items={infoItems}
        textStyle={commonStyles.userProfileInfoLine}
      />

      <AsyncActionButton
        label={showRawUserInfo ? 'Hide Raw User Info' : 'Show Raw User Info'}
        onPress={onToggleRawUserInfo}
      />

      {showRawUserInfo ? (
        <UserProfileJsonBlock title="Raw User Info" payload={userInfo} />
      ) : null}
    </View>
  );
}
