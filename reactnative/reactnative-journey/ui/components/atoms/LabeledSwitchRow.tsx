/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Switch, Text, TextStyle, View, ViewStyle } from 'react-native';
import { commonControlTokens, commonStyles } from '../../../src/styles/common';
import { labeledSwitchRowStyles as styles } from '../../../src/styles/componentStyles';
import { colors } from '../../../src/styles/colors';

type LabeledSwitchRowProps = {
  /**
   * Label rendered on the left side.
   */
  label: string;
  /**
   * Current switch value.
   */
  value: boolean;
  /**
   * Change handler.
   */
  onValueChange: () => void;
  /**
   * Optional disabled flag.
   */
  disabled?: boolean;
  /**
   * Optional row style override.
   */
  rowStyle?: ViewStyle;
  /**
   * Optional label style override.
   */
  labelStyle?: TextStyle;
};

/**
 * Renders a reusable label + switch row used by settings/collector panels.
 *
 * @param props Labeled switch row props.
 * @returns Labeled switch row element.
 */
export default function LabeledSwitchRow(
  props: LabeledSwitchRowProps,
): React.ReactElement {
  const { label, value, onValueChange, disabled, rowStyle, labelStyle } = props;

  return (
    <View style={[styles.row, rowStyle]}>
      <Text style={[commonStyles.inputLabel, styles.label, labelStyle]}>
        {label}
      </Text>
      <Switch
        value={value}
        onValueChange={onValueChange}
        disabled={disabled}
        trackColor={commonControlTokens.primarySwitchTrackColor}
        thumbColor={colors.surface}
      />
    </View>
  );
}
