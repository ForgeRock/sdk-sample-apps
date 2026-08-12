/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Modal, Pressable, Text, TextInput, View } from 'react-native';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';
import type { DeviceRenameTarget } from '../../types';

/**
 * Props for the device rename modal.
 */
type DeviceRenameModalProps = {
  /**
   * Current rename target state.
   */
  renameTarget: DeviceRenameTarget | null;
  /**
   * Dismiss handler for the modal.
   */
  onDismiss: () => void;
  /**
   * Change handler for the rename input draft.
   *
   * @param draft - New text input value.
   * @returns Void.
   */
  onDraftChange: (draft: string) => void;
  /**
   * Submit handler for rename action.
   */
  onSubmit: () => void;
};

/**
 * Renders edit-device-name modal controls.
 *
 * @param props - Device rename modal props.
 * @returns Device rename modal element.
 */
export default function DeviceRenameModal(
  props: DeviceRenameModalProps,
): React.ReactElement {
  const { renameTarget, onDismiss, onDraftChange, onSubmit } = props;
  const isSaveDisabled = !renameTarget?.draft.trim();

  return (
    <Modal
      visible={renameTarget !== null}
      transparent
      animationType="fade"
      onRequestClose={onDismiss}
    >
      <View style={commonStyles.deviceModalBackdrop}>
        <View style={commonStyles.deviceModalCard}>
          <Text style={commonStyles.deviceModalTitle}>Edit Device Name</Text>
          {renameTarget ? (
            <Text style={commonStyles.deviceModalCurrentName}>
              Current name: {renameTarget.device.deviceName}
            </Text>
          ) : null}
          <TextInput
            testID="device-rename-input"
            style={commonStyles.deviceModalInput}
            placeholder="New device name"
            placeholderTextColor={colors.inputPlaceholder}
            value={renameTarget?.draft ?? ''}
            onChangeText={onDraftChange}
            autoFocus
          />
          <View style={commonStyles.deviceModalActions}>
            <Pressable
              style={commonStyles.deviceModalButton}
              onPress={onDismiss}
            >
              <Text style={commonStyles.deviceModalButtonText}>Cancel</Text>
            </Pressable>
            <Pressable
              testID="device-rename-submit"
              style={[
                commonStyles.deviceModalButton,
                commonStyles.deviceModalButtonPrimary,
                isSaveDisabled && commonStyles.deviceModalButtonDisabled,
              ]}
              onPress={onSubmit}
              disabled={isSaveDisabled}
            >
              <Text style={commonStyles.deviceModalButtonPrimaryText}>
                Save
              </Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}
