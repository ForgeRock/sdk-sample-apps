/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ActivityIndicator, Pressable, Text, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type {
  DeviceByKind,
  DeviceKind,
  DeviceOf,
} from '@ping-identity/rn-device-client';
import { commonStyles } from '../../../../src/styles/common';
import { colors } from '../../../../src/styles/colors';
import DeviceListSeparator from '../atoms/DeviceListSeparator';
import DeviceRow from '../molecules/DeviceRow';

/**
 * Device list loading state.
 */
type DeviceListStatus = 'idle' | 'loading' | 'ready' | 'error';

/**
 * Props for the devices list card.
 */
type DeviceListCardProps = {
  /**
   * Selected device kind used in title and empty state.
   */
  selectedType: DeviceKind;
  /**
   * Devices to render.
   */
  devices: DeviceOf<keyof DeviceByKind>[];
  /**
   * Current list status.
   */
  status: DeviceListStatus;
  /**
   * Optional list error message.
   */
  error: string | null;
  /**
   * Trigger list refresh.
   */
  onRefresh: () => void;
  /**
   * Trigger edit flow for a device.
   *
   * @param device - Selected device.
   * @returns Void.
   */
  onEdit: (device: DeviceOf<keyof DeviceByKind>) => void;
  /**
   * Trigger delete flow for a device.
   *
   * @param device - Selected device.
   * @returns Void.
   */
  onDelete: (device: DeviceOf<keyof DeviceByKind>) => void;
};

/**
 * Renders device list status and actions inside a card.
 *
 * @param props - Device list card props.
 * @returns Device list card element.
 */
export default function DeviceListCard(
  props: DeviceListCardProps,
): React.ReactElement {
  const { selectedType, devices, status, error, onRefresh, onEdit, onDelete } =
    props;

  return (
    <View style={commonStyles.deviceListCard}>
      <View style={commonStyles.deviceListHeader}>
        <Text style={commonStyles.deviceListTitle}>
          {selectedType.toUpperCase()} Devices ({devices.length})
        </Text>
        <Pressable
          testID="devices-refresh"
          onPress={onRefresh}
          style={commonStyles.deviceRefreshButton}
        >
          <MaterialIcon name="refresh" size={24} color={colors.primary} />
        </Pressable>
      </View>

      {status === 'loading' ? (
        <View style={commonStyles.deviceLoadingContainer}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      ) : status === 'error' ? (
        <Text style={commonStyles.deviceErrorText}>
          {error ?? 'Error retrieving devices'}
        </Text>
      ) : devices.length === 0 ? (
        <Text style={commonStyles.deviceEmptyText}>
          No {selectedType.toUpperCase()} devices found
        </Text>
      ) : (
        <View testID="devices-list">
          {devices.map((item, index) => (
            <View key={item.id}>
              {index > 0 ? <DeviceListSeparator /> : null}
              <DeviceRow device={item} onEdit={onEdit} onDelete={onDelete} />
            </View>
          ))}
        </View>
      )}
    </View>
  );
}
