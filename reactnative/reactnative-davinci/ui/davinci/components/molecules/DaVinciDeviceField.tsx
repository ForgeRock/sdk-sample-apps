/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type {
  DaVinciFormValue,
  DeviceAuthenticationCollector,
  DeviceOption,
  DeviceRegistrationCollector,
} from '@ping-identity/rn-davinci';
import DaVinciFieldLabel from '../atoms/DaVinciFieldLabel';
import { colors } from '../../../../src/styles/colors';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

type DeviceCollector =
  | DeviceRegistrationCollector
  | DeviceAuthenticationCollector;

/**
 * Resolves the active selected device key from the current form value.
 *
 * @param value Current form value.
 * @returns Device type string when selected, otherwise `null`.
 */
function resolveSelectedDevice(value: DaVinciFormValue | undefined): {
  type: string;
  id?: string;
} | null {
  if (typeof value === 'string') {
    return { type: value };
  }
  if (
    value &&
    typeof value === 'object' &&
    !Array.isArray(value) &&
    'type' in value
  ) {
    const typed = value as { type: string; id?: string };
    return { type: typed.type, id: typed.id };
  }
  return null;
}

/**
 * Builds the value submitted when a device is tapped.
 *
 * @param collectorType Collector discriminator.
 * @param device Selected device option.
 * @returns Value to submit through {@link onChange}.
 */
function buildDeviceValue(
  collectorType: DeviceCollector['type'],
  device: DeviceOption,
): DaVinciFormValue {
  if (collectorType === 'DEVICE_REGISTRATION') {
    return { type: device.type };
  }
  return {
    type: device.type,
    id: device.id,
    description: device.description,
  };
}

/**
 * Determines whether a device option matches the current selection.
 *
 * @param selection Active selection.
 * @param device Device option to check.
 * @returns True when the device matches the selection.
 */
function isDeviceSelected(
  selection: { type: string; id?: string } | null,
  device: DeviceOption,
): boolean {
  if (!selection) {
    return false;
  }
  if (selection.id && device.id) {
    return selection.id === device.id && selection.type === device.type;
  }
  return selection.type === device.type;
}

/**
 * Renders a {@link DeviceRegistrationCollector} or {@link DeviceAuthenticationCollector}
 * as a vertical card list.
 *
 * @param props Renderer props.
 * @returns Device field element.
 */
export default function DaVinciDeviceField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, value, onChange } = props;
  const deviceCollector = collector as DeviceCollector;
  const selection = resolveSelectedDevice(value);

  return (
    <View style={davinciFieldStyles.card}>
      <DaVinciFieldLabel
        label={deviceCollector.label}
        required={deviceCollector.required}
      />
      {deviceCollector.devices.map(device => {
        const isSelected = isDeviceSelected(selection, device);
        return (
          <TouchableOpacity
            key={`${device.type}-${device.id ?? device.title}`}
            accessibilityRole="button"
            accessibilityState={{ selected: isSelected }}
            onPress={() =>
              onChange(buildDeviceValue(deviceCollector.type, device))
            }
            style={[
              davinciFieldStyles.deviceCard,
              isSelected ? davinciFieldStyles.deviceCardSelected : null,
            ]}
          >
            <View style={davinciFieldStyles.deviceIcon}>
              <MaterialIcon
                name="devices"
                size={20}
                color={isSelected ? colors.primary : colors.iconBody}
              />
            </View>
            <View style={davinciFieldStyles.deviceInfo}>
              <Text style={davinciFieldStyles.deviceTitle}>{device.title}</Text>
              {device.description ? (
                <Text style={davinciFieldStyles.deviceDescription}>
                  {device.description}
                </Text>
              ) : null}
            </View>
            {isSelected ? (
              <MaterialIcon
                name="check-circle"
                size={20}
                color={colors.primary}
              />
            ) : null}
          </TouchableOpacity>
        );
      })}
    </View>
  );
}
