/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import { useEffect, useRef } from 'react';
import { Alert } from 'react-native';
import { PingError } from '@ping-identity/rn-types';
import { collectDeviceProfileForJourney } from '@ping-identity/rn-device-profile';
import type {
  JourneyClient,
  JourneyNextInput,
  JourneyNode,
} from '@ping-identity/rn-journey';
import {
  DEVICE_PROFILE_COLLECTORS,
  type ContinueNodeAutomationPolicy,
} from '../utils/clientPanel';

/**
 * Configuration contract for `useJourneyAutomationEffects`.
 */
export type UseJourneyAutomationEffectsOptions = {
  /**
   * Active node state.
   */
  node: JourneyNode | null;
  /**
   * True while Journey action is in-flight.
   */
  loading: boolean;
  /**
   * Active Journey client.
   */
  journeyClient: JourneyClient;
  /**
   * Helper submit readiness state.
   */
  formCanSubmit: boolean;
  /**
   * Helper-built next input.
   */
  formInput: JourneyNextInput;
  /**
   * Stable key representing callback layout for dedupe.
   */
  continueNodeKey: string;
  /**
   * Device profile callback request key for dedupe.
   */
  deviceProfileRequestKey: string;
  /**
   * True when a DeviceProfile callback is present.
   */
  hasDeviceProfileCallback: boolean;
  /**
   * Evaluated automation policy.
   */
  automationPolicy: ContinueNodeAutomationPolicy;
  /**
   * Journey next action.
   */
  next: (input?: JourneyNextInput) => Promise<JourneyNode>;
};

/**
 * Runs sample-app automation side effects for ContinueNode handling.
 *
 * @param options - Automation effect options.
 * @returns Void.
 */
export function useJourneyAutomationEffects(
  options: UseJourneyAutomationEffectsOptions,
): void {
  const {
    node,
    loading,
    journeyClient,
    formCanSubmit,
    formInput,
    continueNodeKey,
    deviceProfileRequestKey,
    hasDeviceProfileCallback,
    automationPolicy,
    next,
  } = options;
  const isContinueNode = node?.type === 'ContinueNode';
  // Prevent duplicate auto-submit for the same callback layout.
  const lastAutoSubmitNodeKeyRef = useRef<string | null>(null);
  // Prevent duplicate device-profile collection for the same request payload.
  const lastAutoDeviceProfileRequestKeyRef = useRef<string | null>(null);
  // Keep one active polling timer at a time across renders.
  const pollingTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (!isContinueNode) {
      lastAutoSubmitNodeKeyRef.current = null;
    }
  }, [isContinueNode]);

  useEffect(() => {
    if (!automationPolicy.canAutoSubmit) {
      return;
    }
    if (!formCanSubmit || !continueNodeKey) {
      return;
    }
    if (lastAutoSubmitNodeKeyRef.current === continueNodeKey) {
      return;
    }

    // Mark before awaiting to avoid duplicate submits during quick re-renders.
    lastAutoSubmitNodeKeyRef.current = continueNodeKey;
    void next(formInput).catch(() => {
      // Hook state captures the error.
    });
  }, [
    automationPolicy.canAutoSubmit,
    continueNodeKey,
    formCanSubmit,
    formInput,
    next,
  ]);

  useEffect(() => {
    if (!automationPolicy.canAutoPoll) {
      if (pollingTimerRef.current) {
        clearTimeout(pollingTimerRef.current);
        pollingTimerRef.current = null;
      }
      return;
    }

    if (pollingTimerRef.current) {
      // Timer already scheduled for this poll window.
      return;
    }

    pollingTimerRef.current = setTimeout(() => {
      pollingTimerRef.current = null;
      void next({}).catch(() => {
        // Hook state captures the error.
      });
    }, automationPolicy.pollingDelayMs);

    return () => {
      if (pollingTimerRef.current) {
        clearTimeout(pollingTimerRef.current);
        pollingTimerRef.current = null;
      }
    };
  }, [automationPolicy.canAutoPoll, automationPolicy.pollingDelayMs, next]);

  useEffect(() => {
    if (!isContinueNode || !hasDeviceProfileCallback || loading) {
      if (!isContinueNode) {
        lastAutoDeviceProfileRequestKeyRef.current = null;
      }
      return;
    }

    if (!deviceProfileRequestKey) {
      return;
    }

    if (
      lastAutoDeviceProfileRequestKeyRef.current === deviceProfileRequestKey
    ) {
      return;
    }

    // Mark before async work to dedupe on fast render/update cycles.
    lastAutoDeviceProfileRequestKeyRef.current = deviceProfileRequestKey;

    const runAutoDeviceProfile = async (): Promise<void> => {
      try {
        await collectDeviceProfileForJourney(journeyClient, [
          ...DEVICE_PROFILE_COLLECTORS,
        ]);

        if (automationPolicy.canAutoSubmitAfterDeviceProfile) {
          await next({});
        }
      } catch (cause) {
        Alert.alert(
          'Device profile failed',
          cause instanceof PingError
            ? `[${cause.code}] ${cause.message}`
            : String(cause),
        );
      }
    };

    void runAutoDeviceProfile();
  }, [
    automationPolicy.canAutoSubmitAfterDeviceProfile,
    deviceProfileRequestKey,
    hasDeviceProfileCallback,
    isContinueNode,
    journeyClient,
    loading,
    next,
  ]);
}
