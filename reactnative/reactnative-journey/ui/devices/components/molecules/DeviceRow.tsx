/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Pressable, Text, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { DeviceByKind, DeviceOf } from '@ping-identity/rn-device-client';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';

/**
 * Props for a single device list row.
 */
type DeviceRowProps = {
  /**
   * Device rendered by this row.
   */
  device: DeviceOf<keyof DeviceByKind>;
  /**
   * Called when edit icon is pressed.
   *
   * @param device - Selected device.
   * @returns Void.
   */
  onEdit: (device: DeviceOf<keyof DeviceByKind>) => void;
  /**
   * Called when delete icon is pressed.
   *
   * @param device - Selected device.
   * @returns Void.
   */
  onDelete: (device: DeviceOf<keyof DeviceByKind>) => void;
};

/**
 * Renders a device row with edit and delete actions.
 *
 * @param props - Device row props.
 * @returns Device row element.
 */
export default function DeviceRow(props: DeviceRowProps): React.ReactElement {
  const { device, onEdit, onDelete } = props;

  return (
    <View testID={`device-row-${device.id}`} style={commonStyles.deviceRow}>
      <Text style={commonStyles.deviceRowName} numberOfLines={1}>
        {device.deviceName}
      </Text>
      <Pressable
        testID={`device-edit-${device.id}`}
        onPress={() => onEdit(device)}
        style={commonStyles.deviceIconButton}
      >
        <MaterialIcon name="edit" size={20} color={colors.primary} />
      </Pressable>
      <Pressable
        testID={`device-delete-${device.id}`}
        onPress={() => onDelete(device)}
        style={commonStyles.deviceIconButton}
      >
        <MaterialIcon name="delete" size={20} color={colors.error} />
      </Pressable>
    </View>
  );
}
