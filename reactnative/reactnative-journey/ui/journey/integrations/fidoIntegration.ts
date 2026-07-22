/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { FidoClient } from '@ping-identity/rn-fido';
import type { JourneyIntegration } from './types';

/**
 * FIDO integration options.
 */
export type FidoIntegrationOptions = {
  /**
   * Reads the current device name input value for a FIDO registration field.
   * Returns undefined when no value has been entered yet.
   *
   * @param fieldId - Normalized form field id.
   * @returns Current device name value if present.
   */
  readDeviceNameInput: (fieldId: string) => string | undefined;
  /**
   * Resolves a fallback system device name used when the user has not entered
   * one in the registration field.
   *
   * @returns Device name to send to the native SDK.
   */
  resolveDefaultDeviceName: () => Promise<string>;
  /**
   * When true, a FIDO authentication cancellation is reported as a non-fatal
   * outcome instead of being rethrown.
   */
  continueOnAuthenticationCancel?: boolean;
};

/**
 * Builds the Journey integration for FIDO registration and authentication
 * callbacks backed by `@ping-identity/rn-fido`.
 *
 * Only FIDO authentication is considered auto-forwardable by default.
 * FIDO registration exposes a device-name text field that must be rendered
 * for the user before submission.
 *
 * @param fido - FIDO client created via `createFidoClient(...)`.
 * @param options - Additional integration wiring options.
 * @returns Integration descriptor consumed by the auto-forwarder.
 */
export function fidoIntegration(
  fido: FidoClient,
  options: FidoIntegrationOptions,
): JourneyIntegration {
  return {
    id: 'fido',
    callbackTypes: ['FidoRegistrationCallback', 'FidoAuthenticationCallback'],
    canAutoForwardField(field) {
      return field.ref.type === 'FidoAuthenticationCallback';
    },
    async run(field, journey) {
      if (field.ref.type === 'FidoRegistrationCallback') {
        const input = options.readDeviceNameInput(field.id)?.trim();
        const deviceName =
          input && input.length > 0
            ? input
            : await options.resolveDefaultDeviceName();
        await fido.registerForJourney(journey, {
          index: field.ref.typeIndex,
          deviceName,
        });
        return {};
      }

      if (field.ref.type === 'FidoAuthenticationCallback') {
        try {
          await fido.authenticateForJourney(journey, {
            index: field.ref.typeIndex,
          });
          return {};
        } catch (error) {
          if (
            options.continueOnAuthenticationCancel &&
            isFidoAuthenticationCancelled(error)
          ) {
            return { cancelled: true };
          }
          throw error;
        }
      }
      return {};
    },
  };
}

/**
 * Returns true when the supplied error represents a user-cancelled FIDO
 * authentication prompt.
 */
function isFidoAuthenticationCancelled(error: unknown): boolean {
  if (!error || typeof error !== 'object') {
    return false;
  }
  const code = (error as { code?: unknown }).code;
  return code === 'FIDO_AUTHENTICATE_CANCELLED';
}
