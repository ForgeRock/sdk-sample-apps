/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { MultiSelectCollector } from '@ping-identity/rn-davinci';
import DaVinciFieldLabel from '../atoms/DaVinciFieldLabel';
import { colors } from '../../../../src/styles/colors';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Resolves the active selection set for a multi-select renderer.
 *
 * @param value Current form value.
 * @param collector Underlying collector.
 * @returns Selection set of currently selected option values.
 */
function resolveSelection(
  value: unknown,
  collector: MultiSelectCollector,
): Set<string> {
  if (Array.isArray(value)) {
    return new Set(value as string[]);
  }
  return new Set(collector.value ?? []);
}

/**
 * Renders a {@link MultiSelectCollector} as a checkbox-style option list.
 *
 * @param props Renderer props.
 * @returns Multi-select field element.
 */
export default function DaVinciMultiSelectField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, value, onChange } = props;
  const multiCollector = collector as MultiSelectCollector;
  const selection = resolveSelection(value, multiCollector);

  const toggle = (optionValue: string): void => {
    const next = new Set(selection);
    if (next.has(optionValue)) {
      next.delete(optionValue);
    } else {
      next.add(optionValue);
    }
    onChange(Array.from(next));
  };

  return (
    <View style={davinciFieldStyles.card}>
      <DaVinciFieldLabel
        label={multiCollector.label}
        required={multiCollector.required}
      />
      {multiCollector.options.map(option => {
        const isSelected = selection.has(option.value);
        return (
          <TouchableOpacity
            key={option.value}
            accessibilityRole="checkbox"
            accessibilityState={{ checked: isSelected }}
            onPress={() => toggle(option.value)}
            style={[
              davinciFieldStyles.optionRow,
              isSelected ? davinciFieldStyles.optionRowSelected : null,
            ]}
          >
            <View
              style={[
                davinciFieldStyles.optionCheckbox,
                isSelected ? davinciFieldStyles.optionCheckboxSelected : null,
              ]}
            >
              {isSelected ? (
                <MaterialIcon name="check" size={12} color={colors.white} />
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
    </View>
  );
}
