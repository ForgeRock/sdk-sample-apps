/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a fallback panel for collector types not yet supported by the
 * sample UI (e.g. plugin-driven `integration_required` collectors).
 *
 * @param props Renderer props.
 * @returns Unsupported field element.
 */
export default function DaVinciUnsupportedField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector } = props;
  return (
    <View style={davinciFieldStyles.unsupportedCard}>
      <Text style={davinciFieldStyles.unsupportedText}>
        {`Unsupported collector "${collector.type}" (key: ${collector.key}).`}
      </Text>
    </View>
  );
}
