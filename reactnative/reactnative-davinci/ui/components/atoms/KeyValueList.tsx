/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { StyleProp, Text, TextStyle, View, ViewStyle } from 'react-native';

/**
 * Label/value pair item.
 */
export type KeyValueItem = {
  label: string;
  value: string;
};

type KeyValueListProps = {
  /**
   * Items to render in order.
   */
  items: readonly KeyValueItem[];
  /**
   * Text style for each rendered line.
   */
  textStyle: StyleProp<TextStyle>;
  /**
   * Optional container style.
   */
  style?: StyleProp<ViewStyle>;
};

/**
 * Renders key/value lines using a shared text style.
 *
 * @param props List props.
 * @returns Key/value list element.
 */
export default function KeyValueList(
  props: KeyValueListProps,
): React.ReactElement {
  const { items, textStyle, style } = props;

  return (
    <View style={style}>
      {items.map(item => (
        <Text key={item.label} style={textStyle}>
          {item.label}: {item.value}
        </Text>
      ))}
    </View>
  );
}
