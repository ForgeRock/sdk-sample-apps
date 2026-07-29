/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type {
  JourneyCallbackType,
  JourneyClient,
  JourneyNormalizedField,
} from '@ping-identity/rn-journey';

/**
 * Outcome of running a Journey integration against a single callback field.
 */
export type JourneyIntegrationRunResult = {
  /**
   * True when execution ended due to user cancellation that the app chose to
   * treat as non-fatal (e.g. FIDO authentication cancel with fallback path).
   */
  cancelled?: boolean;
};

/**
 * Describes how a single native module (FIDO, Binding, IdP, …) executes
 * integration-required callbacks emitted by the Journey helper.
 */
export interface JourneyIntegration {
  /**
   * Stable identifier used in debug logs.
   */
  readonly id: string;
  /**
   * Callback types this integration is responsible for.
   */
  readonly callbackTypes: readonly JourneyCallbackType[];
  /**
   * Returns true when the provided field can be auto-forwarded without any
   * prior user input. Auto-forwardable fields are executed automatically when
   * the surrounding node has no other manual input to collect.
   *
   * @param field - Normalized Journey form field.
   * @returns Whether the integration may auto-run the field unattended.
   */
  canAutoForwardField(field: JourneyNormalizedField): boolean;
  /**
   * Executes the integration for a single callback field.
   *
   * @param field - Normalized Journey form field.
   * @param journey - Active Journey client instance.
   * @returns Run outcome used by the caller for follow-up decisions.
   */
  run(
    field: JourneyNormalizedField,
    journey: JourneyClient,
  ): Promise<JourneyIntegrationRunResult>;
}
