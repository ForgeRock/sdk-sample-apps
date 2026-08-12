/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { View } from 'react-native';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import { resolvePromptText, toDisplayString } from './valueReaders';
import type { JourneyFieldRendererProps } from './types';
import PingTextInput from '../../../../components/atoms/PingTextInput';

/**
 * Renders text-like callback fields, including password and number input modes.
 *
 * @param props - Field renderer props.
 * @returns Text field card.
 */
export default function JourneyTextField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field, currentValue, setFieldValue } = props;
  const promptText = resolvePromptText(field.prompt, field.message);
  const isPasswordField = field.kind === 'password';
  const isDeviceNameField =
    field.ref.type === 'FidoRegistrationCallback' ||
    field.ref.type === 'DeviceBindingCallback';
  const secureTextEntry = isPasswordField;
  const label = isDeviceNameField
    ? 'Device Name'
    : promptText.length > 0
      ? promptText
      : field.ref.type;
  const placeholder = isDeviceNameField
    ? 'Enter device name'
    : promptText.length > 0
      ? promptText
      : 'Enter value';

  return (
    <View style={fieldStyles.card}>
      <PingTextInput
        label={label}
        value={toDisplayString(currentValue)}
        onChangeText={text => setFieldValue(field.id, text)}
        secureTextEntry={secureTextEntry}
        allowPasswordToggle={isPasswordField}
        keyboardType={field.kind === 'number' ? 'numeric' : 'default'}
        placeholder={placeholder}
        autoCapitalize="none"
      />
    </View>
  );
}
