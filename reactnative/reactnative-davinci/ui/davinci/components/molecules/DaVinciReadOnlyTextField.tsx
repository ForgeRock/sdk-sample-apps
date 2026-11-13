/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import type { ReadOnlyTextCollector } from '@ping-identity/rn-davinci';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link ReadOnlyTextCollector} as a read-only content block,
 * with an optional title when `titleEnabled` is `true`.
 *
 * @param props Renderer props.
 * @returns Read-only text element.
 */
export default function DaVinciReadOnlyTextField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector } = props;
  const readOnlyCollector = collector as ReadOnlyTextCollector;

  return (
    <View style={davinciFieldStyles.card}>
      {readOnlyCollector.titleEnabled && readOnlyCollector.title ? (
        <Text style={davinciFieldStyles.fieldLabel}>
          {readOnlyCollector.title}
        </Text>
      ) : null}
      <Text style={davinciFieldStyles.labelContent}>
        {readOnlyCollector.content}
      </Text>
    </View>
  );
}
