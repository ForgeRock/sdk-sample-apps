/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useState } from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import type {
  DaVinciFieldValidationError,
  SingleSelectCollector,
} from '@ping-identity/rn-davinci';
import DaVinciFieldLabel from '../atoms/DaVinciFieldLabel';
import DaVinciErrorList from '../atoms/DaVinciErrorList';
import PickerModal from '../atoms/PickerModal';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Renders a {@link SingleSelectCollector}.
 *
 * @remarks
 * - `DROPDOWN` type: bottom-sheet modal picker
 * - `RADIO` / `SINGLE_SELECT` types: vertical radio-button list
 *
 * @param props Renderer props.
 * @returns Single-select field element.
 */
export default function DaVinciSingleSelectField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, value, onChange, onValidate } = props;
  const selectCollector = collector as SingleSelectCollector;
  const selectedValue =
    typeof value === 'string' ? value : selectCollector.value;

  const [modalVisible, setModalVisible] = useState(false);
  const [validationErrors, setValidationErrors] = useState<
    DaVinciFieldValidationError[] | null
  >(null);

  const handleSelect = (next: string) => {
    setValidationErrors(null);
    onChange(next);
    onValidate(collector.key, next)
      .then(setValidationErrors)
      .catch(error => {
        console.warn('[DaVinci] Select validation failed:', error);
      });
  };

  if (selectCollector.type === 'DROPDOWN') {
    return (
      <View style={davinciFieldStyles.card}>
        <DaVinciFieldLabel
          label={selectCollector.label}
          required={selectCollector.required}
        />
        <PickerModal
          label={selectCollector.label}
          options={selectCollector.options}
          selectedValue={selectedValue}
          visible={modalVisible}
          onOpen={() => setModalVisible(true)}
          onClose={() => setModalVisible(false)}
          onSelect={handleSelect}
        />
        <DaVinciErrorList errors={validationErrors ?? undefined} />
      </View>
    );
  }

  return (
    <View style={davinciFieldStyles.card}>
      <DaVinciFieldLabel
        label={selectCollector.label}
        required={selectCollector.required}
      />
      {selectCollector.options.map(option => {
        const isSelected = option.value === selectedValue;
        return (
          <TouchableOpacity
            key={option.value}
            accessibilityRole="radio"
            accessibilityState={{ selected: isSelected }}
            onPress={() => handleSelect(option.value)}
            style={[
              davinciFieldStyles.optionRow,
              isSelected ? davinciFieldStyles.optionRowSelected : null,
            ]}
          >
            <View
              style={[
                davinciFieldStyles.optionRadio,
                isSelected ? davinciFieldStyles.optionRadioSelected : null,
              ]}
            >
              {isSelected ? (
                <View style={davinciFieldStyles.optionRadioInner} />
              ) : null}
            </View>
            <Text
              style={[
                davinciFieldStyles.optionRowText,
                isSelected ? davinciFieldStyles.optionRowTextSelected : null,
              ]}
            >
              {option.label}
            </Text>
          </TouchableOpacity>
        );
      })}
      <DaVinciErrorList errors={validationErrors ?? undefined} />
    </View>
  );
}
