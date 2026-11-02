/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { View } from 'react-native';
import type {
  DaVinciFieldValidationError,
  TextCollector,
} from '@ping-identity/rn-davinci';
import PingTextInput from '../../../components/atoms/PingTextInput';
import DaVinciErrorList from '../atoms/DaVinciErrorList';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link TextCollector} as a single-line text input.
 *
 * @param props Renderer props.
 * @returns Text field element.
 */
export default function DaVinciTextField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, value, onChange, onValidate } = props;
  const [validationErrors, setValidationErrors] = useState<
    DaVinciFieldValidationError[] | null
  >(null);
  const textCollector = collector as TextCollector;
  const stringValue = typeof value === 'string' ? value : textCollector.value;
  const isMultiline = stringValue.length > 60;

  return (
    <View style={davinciFieldStyles.card}>
      <PingTextInput
        label={
          textCollector.required
            ? `${textCollector.label} *`
            : textCollector.label
        }
        value={stringValue}
        onChangeText={value => {
          setValidationErrors(null);
          onChange(value);
        }}
        onBlur={() => {
          onValidate(collector.key, stringValue)
            .then(setValidationErrors)
            .catch(error => {
              console.warn('[DaVinci] Text validation failed:', error);
            });
        }}
        autoCapitalize="none"
        autoCorrect={false}
        multiline={isMultiline}
      />
      <DaVinciErrorList errors={validationErrors ?? undefined} />
    </View>
  );
}
