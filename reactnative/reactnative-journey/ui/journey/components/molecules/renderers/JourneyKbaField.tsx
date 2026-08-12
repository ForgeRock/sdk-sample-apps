/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useMemo, useState } from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { journeyFieldRendererStyles as fieldStyles } from '../../../../../src/styles/journeyStyles';
import {
  readBoolean,
  readString,
  resolveOptionLabel,
  resolvePromptText,
} from './valueReaders';
import type { JourneyFieldRendererProps } from './types';
import PingTextInput from '../../../../components/atoms/PingTextInput';

type JourneyKbaValue = {
  selectedQuestion?: string;
  selectedAnswer?: string;
  allowUserDefinedQuestions?: boolean;
};

/**
 * Renders a KBA callback field.
 *
 * @param props - Field renderer props.
 * @returns KBA field card.
 */
export default function JourneyKbaField(
  props: JourneyFieldRendererProps,
): React.ReactElement {
  const { field, currentValue, setFieldValue } = props;
  const promptText = resolvePromptText(field.prompt, field.message);
  const [isQuestionDropdownOpen, setQuestionDropdownOpen] =
    useState<boolean>(false);

  const kbaValue: JourneyKbaValue = (currentValue as
    | JourneyKbaValue
    | undefined) ?? {
    selectedQuestion: '',
    selectedAnswer: '',
    allowUserDefinedQuestions: false,
  };
  const questionOptions = useMemo(
    () =>
      (field.options ?? []).map(option =>
        resolveOptionLabel(option.label, option.value, option.index),
      ),
    [field.options],
  );
  const selectedQuestion = readString(kbaValue.selectedQuestion);
  const selectedQuestionLabel =
    selectedQuestion.length > 0
      ? selectedQuestion
      : 'Select a security question';

  return (
    <View style={fieldStyles.card}>
      {promptText.length > 0 ? (
        <Text style={fieldStyles.promptText}>{promptText}</Text>
      ) : null}
      {questionOptions.length > 0 ? (
        <View style={fieldStyles.optionWrap}>
          <TouchableOpacity
            style={fieldStyles.dropdownTrigger}
            onPress={() =>
              setQuestionDropdownOpen(previousValue => !previousValue)
            }
          >
            <Text style={fieldStyles.dropdownTriggerText}>
              {selectedQuestionLabel}
            </Text>
            <Text style={fieldStyles.dropdownChevron}>
              {isQuestionDropdownOpen ? '▲' : '▼'}
            </Text>
          </TouchableOpacity>
          {isQuestionDropdownOpen ? (
            <View style={fieldStyles.dropdownMenu}>
              {questionOptions.map((question, index) => (
                <TouchableOpacity
                  key={`${field.id}:question:${index}`}
                  style={[
                    fieldStyles.dropdownMenuItem,
                    selectedQuestion === question
                      ? fieldStyles.dropdownMenuItemSelected
                      : null,
                  ]}
                  onPress={() => {
                    setFieldValue(field.id, {
                      selectedQuestion: question,
                      selectedAnswer: readString(kbaValue.selectedAnswer),
                      allowUserDefinedQuestions: readBoolean(
                        kbaValue.allowUserDefinedQuestions,
                        false,
                      ),
                    });
                    setQuestionDropdownOpen(false);
                  }}
                >
                  <Text
                    style={[
                      fieldStyles.dropdownMenuItemText,
                      selectedQuestion === question
                        ? fieldStyles.dropdownMenuItemTextSelected
                        : null,
                    ]}
                  >
                    {question}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          ) : null}
        </View>
      ) : null}
      <PingTextInput
        containerStyle={
          questionOptions.length > 0 ? fieldStyles.topGap : undefined
        }
        label="Answer"
        value={readString(kbaValue.selectedAnswer)}
        onChangeText={text =>
          setFieldValue(field.id, {
            selectedQuestion,
            selectedAnswer: text,
            allowUserDefinedQuestions: readBoolean(
              kbaValue.allowUserDefinedQuestions,
              false,
            ),
          })
        }
        placeholder="Answer"
        autoCapitalize="none"
      />
    </View>
  );
}
