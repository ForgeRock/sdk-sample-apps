/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { commonStyles } from '../../../../../src/styles/common';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import {
  readNumber,
  resolveOptionLabel,
  resolvePromptText,
} from './valueReaders';
import type { JourneyFieldRendererProps } from './types';

/**
 * Renders a choice callback field.
 *
 * @param props - Field renderer props.
 * @returns Choice field card.
 */
export default function JourneyChoiceField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field, currentValue, setFieldValue } = props;
  const selected = readNumber(currentValue, readNumber(field.defaultValue, -1));
  const promptText = resolvePromptText(field.prompt, field.message);

  return (
    <View style={fieldStyles.card}>
      {promptText.length > 0 ? (
        <Text style={fieldStyles.promptText}>{promptText}</Text>
      ) : null}
      {!field.options || field.options.length === 0 ? (
        <Text style={fieldStyles.helperText}>
          No options were provided by this callback.
        </Text>
      ) : null}
      {field.options?.map(option => (
        <TouchableOpacity
          key={`${field.id}:${option.index}`}
          style={[
            commonStyles.buttonSecondary,
            selected === option.index ? fieldStyles.selectedOption : null,
          ]}
          onPress={() => setFieldValue(field.id, option.index)}
        >
          <Text style={commonStyles.buttonTextSecondary}>
            {resolveOptionLabel(option.label, option.value, option.index)}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}
