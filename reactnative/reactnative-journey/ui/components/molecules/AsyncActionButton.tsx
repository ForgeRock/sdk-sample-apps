/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {
  ActivityIndicator,
  Text,
  TouchableOpacity,
  type StyleProp,
  type TextStyle,
  type ViewStyle,
} from 'react-native';
import { commonStyles } from '../../../src/styles/common';
import { colors } from '../../../src/styles/colors';

/**
 * Visual variants supported by `AsyncActionButton`.
 */
export type AsyncActionButtonVariant = 'primary' | 'secondary' | 'danger';

/**
 * Props for the reusable async action button.
 */
export type AsyncActionButtonProps = {
  /**
   * Button label text.
   */
  label: string;
  /**
   * Press handler for the action.
   */
  onPress: () => void;
  /**
   * Whether to show a loading indicator and disable interaction.
   */
  loading?: boolean;
  /**
   * Whether the button should be disabled.
   */
  disabled?: boolean;
  /**
   * Button visual variant.
   */
  variant?: AsyncActionButtonVariant;
  /**
   * Optional style override for the outer button.
   */
  style?: StyleProp<ViewStyle>;
  /**
   * Optional style override for the label text.
   */
  textStyle?: StyleProp<TextStyle>;
};

/**
 * Renders a reusable action button with loading and disabled handling.
 *
 * @param props Button props.
 * @returns Async action button element.
 */
export default function AsyncActionButton(
  props: AsyncActionButtonProps,
): React.ReactElement {
  const {
    label,
    onPress,
    loading = false,
    disabled = false,
    variant = 'primary',
    style,
    textStyle,
  } = props;

  const isDisabled = disabled || loading;
  const buttonStyle =
    variant === 'secondary'
      ? commonStyles.buttonSecondary
      : variant === 'danger'
        ? commonStyles.buttonDanger
        : commonStyles.buttonPrimary;
  const labelStyle =
    variant === 'secondary'
      ? commonStyles.buttonTextSecondary
      : commonStyles.buttonText;
  const loadingColor = variant === 'secondary' ? colors.primary : colors.white;

  return (
    <TouchableOpacity
      style={[
        buttonStyle,
        isDisabled ? commonStyles.homeRowDisabled : null,
        style,
      ]}
      disabled={isDisabled}
      onPress={onPress}
    >
      {loading ? (
        <ActivityIndicator size="small" color={loadingColor} />
      ) : (
        <Text style={[labelStyle, textStyle]}>{label}</Text>
      )}
    </TouchableOpacity>
  );
}
