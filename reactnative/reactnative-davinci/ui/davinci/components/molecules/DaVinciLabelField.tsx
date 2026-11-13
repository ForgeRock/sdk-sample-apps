/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { View } from 'react-native';
import type { LabelCollector } from '@ping-identity/rn-davinci';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import RichTextLabel from './RichTextLabel';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link LabelCollector} as a read-only block of text.
 *
 * @param props Renderer props.
 * @returns Label element.
 */
export default function DaVinciLabelField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector } = props;
  const labelCollector = collector as LabelCollector;
  return (
    <View style={davinciFieldStyles.card}>
      <RichTextLabel
        text={labelCollector.content}
        richContent={labelCollector.richContent}
        style={davinciFieldStyles.labelContent}
      />
    </View>
  );
}
