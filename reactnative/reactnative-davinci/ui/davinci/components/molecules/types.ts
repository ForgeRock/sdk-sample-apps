/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { FidoCollector } from '@ping-identity/rn-fido';
import type { IdpCollector } from '@ping-identity/rn-external-idp';
import type {
  DaVinciFieldValidationError,
  DaVinciFormValue,
  DaVinciNormalizedCollector,
  PollingCollector,
  PollingStatus,
} from '@ping-identity/rn-davinci';

/**
 * Shared props for every DaVinci collector renderer.
 */
export type DaVinciCollectorRendererProps = {
  /**
   * Normalised DaVinci collector to render.
   */
  collector: DaVinciNormalizedCollector;
  /**
   * Current form value for this collector, when present.
   */
  value: DaVinciFormValue | undefined;
  /**
   * Updates the form value for this collector.
   *
   * @param value Next collector value.
   */
  onChange: (value: DaVinciFormValue) => void;
  /**
   * Submits the current form. Used by submit buttons and flow links.
   */
  onSubmit: () => void;
  /**
   * Validates the current value for a collector.
   *
   * @param collectorKey Collector key to validate.
   * @param value Current rendered value for the collector.
   * @returns Validation errors for the collector.
   */
  onValidate: (
    collectorKey: string,
    value: DaVinciFormValue,
  ) => Promise<DaVinciFieldValidationError[]>;
  /**
   * Immediately advances the flow using a specific {@link FlowCollector} key.
   *
   * @param flowKey Flow collector key to submit.
   */
  onFlowAction: (flowKey: string) => void;
  /**
   * Whether the form is currently in a submission state.
   */
  loading: boolean;
  /**
   * Whether the form can currently be submitted.
   */
  canSubmit: boolean;
  /**
   * Called when the user presses a social login button for an IDP collector.
   *
   * @param collector The IdpCollector to authorize.
   */
  onIdpAuthorize: (collector: IdpCollector) => Promise<void>;
  /**
   * Runs the native passkey ceremony for a FIDO collector.
   *
   * @param collector The FIDO collector to process.
   */
  onFidoCeremony: (collector: FidoCollector) => Promise<void>;
  /**
   * Streams {@link PollingStatus} updates for a {@link PollingCollector}.
   *
   * @remarks
   * Mirrors `DaVinciClient.pollStatus` scoped to a specific collector key —
   * the molecule owns subscription lifecycle (start on mount, unsubscribe on
   * unmount); the controller owns advancing the flow on a terminal status.
   *
   * @param collector The PollingCollector to poll.
   * @param onStatus Callback invoked with each streamed status tick.
   * @returns An unsubscribe function.
   */
  onPollStatus: (
    collector: PollingCollector,
    onStatus: (status: PollingStatus) => void,
  ) => Promise<() => void>;
};
