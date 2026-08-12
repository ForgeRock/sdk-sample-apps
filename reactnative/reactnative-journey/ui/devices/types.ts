/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type {
  DeviceByKind,
  DeviceKind,
  DeviceOf,
} from '@ping-identity/rn-device-client';

/**
 * Backing session source used by the devices screen.
 */
export type DeviceProvider = 'journey' | 'oidc';

/**
 * Selectable provider option.
 */
export interface DeviceProviderOption {
  /**
   * Provider key.
   */
  key: DeviceProvider;
  /**
   * Display label for the provider.
   */
  label: string;
}

/**
 * Selectable device type option.
 */
export interface DeviceTypeOption {
  /**
   * Device kind key.
   */
  key: DeviceKind;
  /**
   * Display label for the device kind.
   */
  label: string;
}

/**
 * Draft state for the edit-device dialog.
 */
export interface DeviceRenameTarget {
  /**
   * Device kind being edited.
   */
  kind: DeviceKind;
  /**
   * Device currently being edited.
   */
  device: DeviceOf<keyof DeviceByKind>;
  /**
   * Current user-entered name draft.
   */
  draft: string;
}

/**
 * Device-type options rendered by the filter card.
 */
export const DEVICE_TYPES: DeviceTypeOption[] = [
  { key: 'oath', label: 'OATH (TOTP/HOTP)' },
  { key: 'push', label: 'Push Notifications' },
  { key: 'bound', label: 'Bound Devices' },
  { key: 'webAuthn', label: 'WebAuthn/FIDO2' },
  { key: 'profile', label: 'Profile Devices' },
];

/**
 * Session-provider options rendered by the provider card.
 */
export const DEVICE_PROVIDERS: DeviceProviderOption[] = [
  { key: 'journey', label: 'Journey Session' },
  { key: 'oidc', label: 'OIDC Session' },
];
