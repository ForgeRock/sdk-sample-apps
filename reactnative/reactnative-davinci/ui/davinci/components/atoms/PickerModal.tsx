/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import {
  FlatList,
  Modal,
  Text,
  TouchableOpacity,
  TouchableWithoutFeedback,
  View,
} from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { colors } from '../../../../src/styles/colors';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';

export type PickerOption = {
  label: string;
  value: string;
};

type PickerModalProps = {
  label: string;
  options: PickerOption[];
  selectedValue: string;
  placeholder?: string;
  /** Override the trigger button text. Defaults to the selected option's label. */
  triggerLabel?: string;
  visible: boolean;
  onOpen: () => void;
  onClose: () => void;
  onSelect: (value: string) => void;
};

/**
 * Reusable bottom-sheet picker that renders a flat list of options in a modal.
 *
 * @param props Picker props.
 * @returns Trigger button and modal element.
 */
export default function PickerModal(
  props: PickerModalProps,
): React.ReactElement {
  const {
    label,
    options,
    selectedValue,
    placeholder = '',
    triggerLabel,
    visible,
    onOpen,
    onClose,
    onSelect,
  } = props;

  const selectedLabel =
    triggerLabel ?? options.find(o => o.value === selectedValue)?.label ?? '';

  const handleSelect = (value: string): void => {
    onSelect(value);
    onClose();
  };

  return (
    <>
      <TouchableOpacity
        accessibilityRole="combobox"
        accessibilityLabel={label}
        accessibilityState={{ expanded: visible }}
        onPress={onOpen}
        style={davinciFieldStyles.pickerTrigger}
      >
        <Text
          style={
            selectedLabel
              ? davinciFieldStyles.pickerTriggerText
              : davinciFieldStyles.pickerTriggerPlaceholder
          }
        >
          {selectedLabel || placeholder}
        </Text>
        <MaterialIcon
          name="arrow-drop-down"
          size={24}
          color={colors.inputInactiveText}
          style={davinciFieldStyles.pickerChevron}
        />
      </TouchableOpacity>

      <Modal
        visible={visible}
        transparent
        animationType="slide"
        onRequestClose={onClose}
      >
        <TouchableWithoutFeedback onPress={onClose}>
          <View style={davinciFieldStyles.pickerOverlay}>
            <TouchableWithoutFeedback>
              <View style={davinciFieldStyles.pickerSheet}>
                <View style={davinciFieldStyles.pickerSheetHandle} />
                <Text style={davinciFieldStyles.pickerSheetTitle}>{label}</Text>
                <FlatList
                  data={options}
                  keyExtractor={item => item.value}
                  renderItem={({ item }) => {
                    const isSelected = item.value === selectedValue;
                    return (
                      <TouchableOpacity
                        accessibilityRole="radio"
                        accessibilityState={{ selected: isSelected }}
                        onPress={() => handleSelect(item.value)}
                        style={[
                          davinciFieldStyles.pickerOption,
                          isSelected
                            ? davinciFieldStyles.pickerOptionSelected
                            : null,
                        ]}
                      >
                        <Text
                          style={[
                            davinciFieldStyles.pickerOptionText,
                            isSelected
                              ? davinciFieldStyles.pickerOptionTextSelected
                              : null,
                          ]}
                        >
                          {item.label}
                        </Text>
                        {isSelected ? (
                          <MaterialIcon
                            name="check"
                            size={18}
                            color={colors.primary}
                          />
                        ) : null}
                      </TouchableOpacity>
                    );
                  }}
                />
              </View>
            </TouchableWithoutFeedback>
          </View>
        </TouchableWithoutFeedback>
      </Modal>
    </>
  );
}
