/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, View } from 'react-native';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import type { JourneyFieldRendererProps } from './types';

/**
 * Renders a warning card for unsupported or integration-required callbacks.
 *
 * @param props - Field renderer props.
 * @returns Warning field card.
 */
export default function JourneyUnsupportedField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field } = props;

  return (
    <View style={fieldStyles.warningCard}>
      <Text style={fieldStyles.warningTitle}>Callback Notice</Text>
      <Text style={fieldStyles.warningText}>
        {field.executionMode === 'integration_required'
          ? 'Requires additional native integration.'
          : 'Unsupported callback type.'}
      </Text>
    </View>
  );
}
