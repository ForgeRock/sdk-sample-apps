/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import type { FidoCollector } from '@ping-identity/rn-fido';
import { commonStyles } from '../../../../src/styles/common';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Props for {@link DaVinciFidoField}.
 */
export type DaVinciFidoFieldProps = DaVinciCollectorRendererProps & {
  /**
   * Runs the native passkey ceremony for the collector.
   *
   * @param collector The FIDO collector to process.
   */
  onFidoCeremony: (collector: FidoCollector) => Promise<void>;
};

/**
 * Renders a FIDO2 collector as a passkey ceremony button.
 *
 * @param props Renderer props extended with `onFidoCeremony`.
 * @returns Passkey ceremony button element.
 */
export default function DaVinciFidoField(
  props: DaVinciFidoFieldProps,
): React.ReactElement {
  const { collector, loading, onFidoCeremony } = props;
  const fidoCollector = collector as unknown as FidoCollector;
  const actionLabel =
    fidoCollector.action === 'REGISTER' ? 'Register passkey' : 'Use passkey';

  return (
    <View style={davinciFieldStyles.card}>
      <TouchableOpacity
        accessibilityRole="button"
        onPress={() => void onFidoCeremony(fidoCollector)}
        disabled={loading}
        activeOpacity={0.8}
        style={commonStyles.buttonSecondary}
      >
        <Text style={commonStyles.buttonTextSecondary}>
          {fidoCollector.label || actionLabel}
        </Text>
      </TouchableOpacity>
    </View>
  );
}
