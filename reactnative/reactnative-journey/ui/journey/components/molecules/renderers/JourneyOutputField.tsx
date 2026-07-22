/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ScrollView, Text, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { commonStyles } from '../../../../../src/styles/common';
import { colors } from '../../../../../src/styles/colors';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import { resolvePromptText, toDisplayString } from './valueReaders';
import type { JourneyFieldRendererProps } from './types';

/**
 * Renders an output-only callback field.
 *
 * @param props - Field renderer props.
 * @returns Output-only field card.
 */
export default function JourneyOutputField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field } = props;
  const promptText = resolvePromptText(field.prompt, field.message);
  const helperText =
    typeof field.message === 'string' ? field.message.trim() : '';
  const shouldRenderHelperText =
    helperText.length > 0 && helperText !== promptText.trim();
  const messageType =
    typeof field.raw.messageType === 'string'
      ? field.raw.messageType.trim().toUpperCase()
      : '';

  let iconName: string | null = null;
  if (
    field.ref.type === 'TextOutputCallback' ||
    field.ref.type === 'SuspendedTextOutputCallback'
  ) {
    switch (messageType) {
      case 'INFO':
      case 'INFORMATION':
        iconName = 'info';
        break;
      case 'WARNING':
        iconName = 'warning';
        break;
      case 'ERROR':
        iconName = 'error';
        break;
      default:
        iconName = 'settings';
        break;
    }
  }

  return (
    <View style={fieldStyles.card}>
      {promptText.length > 0 ? (
        iconName ? (
          <View style={fieldStyles.outputHeaderRow}>
            <MaterialIcon
              name={iconName}
              size={18}
              color={colors.iconBody}
              style={fieldStyles.outputIcon}
            />
            <Text style={fieldStyles.outputPromptText}>{promptText}</Text>
          </View>
        ) : (
          <Text style={fieldStyles.promptText}>{promptText}</Text>
        )
      ) : null}
      {shouldRenderHelperText ? (
        <Text style={fieldStyles.helperText}>{helperText}</Text>
      ) : null}
      <ScrollView
        style={fieldStyles.payloadScroll}
        nestedScrollEnabled
        keyboardShouldPersistTaps="handled"
        showsVerticalScrollIndicator
        onStartShouldSetResponderCapture={(): boolean => true}
        onMoveShouldSetResponderCapture={(): boolean => true}
      >
        <Text style={commonStyles.codeText}>
          {toDisplayString(field.raw.value)}
        </Text>
      </ScrollView>
    </View>
  );
}
