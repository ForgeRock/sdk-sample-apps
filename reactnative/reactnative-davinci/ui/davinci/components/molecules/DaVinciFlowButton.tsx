/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import type { FlowCollector } from '@ping-identity/rn-davinci';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link FlowCollector} either as a secondary button or a link,
 * depending on whether the type is `FLOW_LINK`.
 *
 * @param props Renderer props.
 * @returns Flow button or link element.
 */
export default function DaVinciFlowButton(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, onFlowAction, loading } = props;
  const flowCollector = collector as FlowCollector;
  const label = flowCollector.label || 'Continue';
  const handlePress = (): void => onFlowAction(flowCollector.key);

  if (flowCollector.type === 'FLOW_LINK') {
    return (
      <TouchableOpacity
        accessibilityRole="link"
        onPress={handlePress}
        disabled={loading}
        style={davinciFieldStyles.flowLink}
      >
        <Text style={davinciFieldStyles.flowLinkText}>{label}</Text>
      </TouchableOpacity>
    );
  }

  return (
    <View style={davinciFieldStyles.card}>
      <AsyncActionButton
        label={label}
        onPress={handlePress}
        loading={loading}
        variant="secondary"
      />
    </View>
  );
}
