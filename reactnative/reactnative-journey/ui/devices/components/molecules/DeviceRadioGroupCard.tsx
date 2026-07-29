/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Pressable, Text, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';

/**
 * Option definition for the device radio-group card.
 */
type DeviceRadioOption<T extends string> = {
  /**
   * Option key value.
   */
  key: T;
  /**
   * Option display label.
   */
  label: string;
};

/**
 * Props for the device radio-group card.
 */
type DeviceRadioGroupCardProps<T extends string> = {
  /**
   * Card title shown above radio options.
   */
  title: string;
  /**
   * Ordered radio options to render.
   */
  options: DeviceRadioOption<T>[];
  /**
   * Currently selected option key.
   */
  selectedKey: T;
  /**
   * Test-id prefix used for each option.
   */
  testIdPrefix: string;
  /**
   * Called when user selects an option.
   *
   * @param key - Newly selected option key.
   * @returns Void.
   */
  onSelect: (key: T) => void;
};

/**
 * Renders a reusable card containing a radio-option group.
 *
 * @typeParam T - Option key union type.
 * @param props - Radio-group card props.
 * @returns Radio-group card element.
 */
export default function DeviceRadioGroupCard<T extends string>(
  props: DeviceRadioGroupCardProps<T>,
): React.ReactElement {
  const { title, options, selectedKey, testIdPrefix, onSelect } = props;

  return (
    <View style={commonStyles.deviceFilterCard}>
      <Text style={commonStyles.deviceFilterTitle}>{title}</Text>
      {options.map(option => (
        <Pressable
          key={option.key}
          testID={`${testIdPrefix}-${option.key}`}
          style={commonStyles.deviceRadioRow}
          onPress={() => onSelect(option.key)}
        >
          <View
            style={[
              commonStyles.deviceRadioOuter,
              selectedKey === option.key &&
                commonStyles.deviceRadioOuterSelected,
            ]}
          >
            {selectedKey === option.key ? (
              <View style={commonStyles.deviceRadioInner} />
            ) : null}
          </View>
          <Text style={commonStyles.deviceRadioLabel}>{option.label}</Text>
        </Pressable>
      ))}
    </View>
  );
}
