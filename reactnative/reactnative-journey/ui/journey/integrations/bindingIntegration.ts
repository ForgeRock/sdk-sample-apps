/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { BindingClient } from '@ping-identity/rn-binding';
import type { JourneyIntegration } from './types';

/**
 * Binding integration options.
 */
export type BindingIntegrationOptions = {
  /**
   * Reads the current device name input value for a DeviceBindingCallback
   * text field. Returns undefined when no value has been entered yet.
   *
   * @param fieldId - Normalized form field id.
   * @returns Current device name value if present.
   */
  readDeviceNameInput?: (fieldId: string) => string | undefined;
  /**
   * Resolver invoked when the user has not entered a device name value.
   * Used as a fallback default so the bind payload always carries a
   * meaningful device name.
   *
   * @remarks
   * When omitted and no user input is present, the native SDK's default is
   * used (`Build.MODEL` on Android, `"Apple"` on iOS).
   *
   * @returns Device name to send with the bind payload.
   */
  resolveDefaultDeviceName?: () => Promise<string>;
};

/**
 * Builds the Journey integration for device binding and signing verifier
 * callbacks backed by `@ping-identity/rn-binding`.
 *
 * `DeviceBindingCallback` exposes a user-editable device-name text field,
 * so it is not auto-forwarded. `DeviceSigningVerifierCallback` has no
 * user input and auto-forwards silently.
 *
 * @param binding - Binding client created via `createBindingClient(...)`.
 * @param options - Optional integration wiring.
 * @returns Integration descriptor consumed by the auto-forwarder.
 */
export function bindingIntegration(
  binding: BindingClient,
  options: BindingIntegrationOptions = {},
): JourneyIntegration {
  return {
    id: 'binding',
    callbackTypes: ['DeviceBindingCallback', 'DeviceSigningVerifierCallback'],
    canAutoForwardField(field) {
      return field.ref.type === 'DeviceSigningVerifierCallback';
    },
    async run(field, journey) {
      if (field.ref.type === 'DeviceBindingCallback') {
        const entered = options.readDeviceNameInput?.(field.id)?.trim();
        const deviceName =
          entered && entered.length > 0
            ? entered
            : await options.resolveDefaultDeviceName?.();
        await binding.bindForJourney(journey, {
          index: field.ref.typeIndex,
          ...(deviceName ? { deviceName } : {}),
        });
        return {};
      }
      if (field.ref.type === 'DeviceSigningVerifierCallback') {
        await binding.signForJourney(journey, {
          index: field.ref.typeIndex,
        });
        return {};
      }
      return {};
    },
  };
}
