/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { View } from 'react-native';
import type { SubmitCollector } from '@ping-identity/rn-davinci';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link SubmitCollector} as a primary submit button.
 *
 * @param props Renderer props.
 * @returns Submit button element.
 */
export default function DaVinciSubmitButton(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, onSubmit, loading, canSubmit } = props;
  const submitCollector = collector as SubmitCollector;
  return (
    <View style={davinciFieldStyles.card}>
      <AsyncActionButton
        label={submitCollector.label || 'Submit'}
        onPress={onSubmit}
        loading={loading}
        disabled={!canSubmit}
        variant="primary"
      />
    </View>
  );
}
