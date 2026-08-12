/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Switch, Text, View } from 'react-native';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import {
  readBoolean,
  resolveContentText,
  resolvePromptText,
} from './valueReaders';
import type { JourneyFieldRendererProps } from './types';

/**
 * Renders a boolean callback field.
 *
 * @param props - Field renderer props.
 * @returns Boolean field card.
 */
export default function JourneyBooleanField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field, currentValue, setFieldValue } = props;
  const promptText = resolvePromptText(field.prompt, field.message);
  const termsText =
    field.ref.type === 'TermsAndConditionsCallback'
      ? resolveContentText((field.raw as Record<string, unknown>).terms)
      : '';

  return (
    <View style={fieldStyles.card}>
      {promptText.length > 0 ? (
        <Text style={fieldStyles.promptText}>
          {promptText}
          {field.required ? ' *' : ''}
        </Text>
      ) : null}
      {termsText.length > 0 ? (
        <Text style={[fieldStyles.helperText, fieldStyles.contentText]}>
          {termsText}
        </Text>
      ) : null}
      <Switch
        value={readBoolean(currentValue, false)}
        onValueChange={value => setFieldValue(field.id, value)}
      />
    </View>
  );
}
