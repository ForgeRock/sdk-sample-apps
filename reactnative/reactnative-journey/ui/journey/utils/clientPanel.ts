/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import type { JourneyNormalizedField } from '@ping-identity/rn-journey';
import Config from 'react-native-config';

/**
 * Storage key used by the sample app to persist recent Journey names.
 */
export const RECENT_JOURNEYS_STORAGE_KEY = 'recentJourneys';

/**
 * Storage key used by the sample app to persist used AM test journey names.
 */
export const USED_TEST_JOURNEYS_STORAGE_KEY = 'usedTestJourneys';

/**
 * Default polling delay used when `PollingWaitCallback` does not provide a wait time.
 */
export const DEFAULT_AUTO_POLLING_WAIT_MS = 3000;

/**
 * Device profile collectors used by the sample app integration path.
 */
export const DEVICE_PROFILE_COLLECTORS = [
  'platform',
  'hardware',
  'network',
  'location',
] as const;

/**
 * Canonical Journey names used by the sample app quick-pick row.
 *
 * @remarks
 * Includes core callback-focused AM test journeys plus common baseline flows.
 */
export const TEST_JOURNEY_NAME_SUGGESTIONS = [
  'NamePasswordCallbackTest',
  'TextInputCallbackTest',
  'StringAttributeInputCallbackTest',
  'NumberAttributeInputCallbackTest',
  'BooleanAttributeInputCallbackTest',
  'ChoiceCallbackTest',
  'ConfirmationCallbackTest',
  'ConsentMappingCallbackTest',
  'HiddenValueCallbackTest',
  'KbaCreateCallbackTest',
  'MetadataCallbackTest',
  'PollingWaitCallbackTest',
  'SuspendedTextCallbackTest',
  'TextOutputCallbackTest',
  'TermsAndConditionCallbackTest',
  'ValidatedPasswordCallbackTest',
  'ValidatedUsernameCallbackTest',
  'DeviceProfileCallbackTest',
  'TEST-e2e-recaptcha-enterprise',
  'TEST_PING_ONE_PROTECT_INITIALIZE',
  'TEST_PING_ONE_PROTECT_EVALUATE',
  'device-bind',
  'device-verifier',
  'key-attestation',
] as const;

/**
 * Enables AM test journey suggestions in development builds.
 *
 * @remarks
 * Keep this `false` for normal sample usage and flip to `true` only when
 * running callback/test-journey validation.
 */
export const ENABLE_AM_TEST_JOURNEY_SUGGESTIONS_IN_DEV = false;

/**
 * Runtime flag used by Journey route UI to decide whether test journeys are shown.
 */
export const SHOW_AM_TEST_JOURNEY_SUGGESTIONS =
  __DEV__ && ENABLE_AM_TEST_JOURNEY_SUGGESTIONS_IN_DEV;

/**
 * Runtime flag used by Journey helper UI to decide whether the debug panel is shown.
 *
 * Controlled by `.env` variable `JOURNEY_SHOW_DEBUG_PANEL` (`true` / `false`).
 */
export const SHOW_JOURNEY_DEBUG_PANEL =
  (Config.JOURNEY_SHOW_DEBUG_PANEL ?? 'false').trim().toLowerCase() === 'true';

/**
 * Returns true when a journey name is one of the built-in AM test journeys.
 *
 * @param journeyName - Journey name to evaluate.
 * @returns True when the journey belongs to the test quick-pick set.
 */
export function isTestJourneyName(journeyName: string): boolean {
  const normalized = journeyName.trim();
  return TEST_JOURNEY_NAME_SUGGESTIONS.some(name => name === normalized);
}

/**
 * Builds normalized recent-journey suggestions.
 *
 * @param recentJourneys - Recently used journey names loaded from storage.
 * @returns Unique recent journey names excluding built-in test suggestions.
 */
export function buildRecentJourneySuggestions(
  recentJourneys: string[],
): string[] {
  const seen = new Set<string>();

  return recentJourneys
    .map(value => value.trim())
    .filter(value => {
      if (!value || seen.has(value) || isTestJourneyName(value)) {
        return false;
      }
      seen.add(value);
      return true;
    });
}

/**
 * Builds normalized used AM test journey names.
 *
 * @param usedJourneys - Raw used journey list loaded from storage.
 * @returns Unique used test journey names.
 */
export function buildUsedTestJourneys(usedJourneys: string[]): string[] {
  const seen = new Set<string>();
  return usedJourneys
    .map(value => value.trim())
    .filter(value => {
      if (!value || seen.has(value) || !isTestJourneyName(value)) {
        return false;
      }
      seen.add(value);
      return true;
    });
}

/**
 * Converts unknown values into display-safe strings.
 *
 * @param value - Arbitrary value.
 * @param fallback - Fallback string.
 * @returns Normalized string.
 */
function readString(value: unknown, fallback = ''): string {
  if (typeof value === 'string') {
    return value;
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  return fallback;
}

/**
 * Extracts a display name from a Journey session payload.
 *
 * @param session - Session payload returned by `user()`.
 * @returns Given name when available.
 */
export function extractGivenName(session: unknown): string | undefined {
  if (!session || typeof session !== 'object') {
    return undefined;
  }

  const userInfo = (session as Record<string, unknown>).userInfo;
  if (!userInfo || typeof userInfo !== 'object') {
    return undefined;
  }

  const givenName = (userInfo as Record<string, unknown>).given_name;
  const normalized = readString(givenName, '');
  return normalized.length > 0 ? normalized : undefined;
}

/**
 * Resolves polling wait time from a normalized polling callback field.
 *
 * @param fields - Normalized callback fields.
 * @returns Polling wait time in milliseconds when available.
 */
export function resolvePollingWaitMs(
  fields: JourneyNormalizedField[],
): number | null {
  const pollingField = fields.find(
    field => field.ref.type === 'PollingWaitCallback',
  );
  if (!pollingField) {
    return null;
  }

  const waitTime = pollingField.raw.waitTime;
  if (
    typeof waitTime === 'number' &&
    Number.isFinite(waitTime) &&
    waitTime > 0
  ) {
    return waitTime;
  }
  if (typeof waitTime === 'string') {
    const parsed = Number(waitTime);
    if (Number.isFinite(parsed) && parsed > 0) {
      return parsed;
    }
  }
  return null;
}

/**
 * Inputs for ContinueNode automation policy evaluation.
 */
export type ContinueNodeAutomationPolicyInput = {
  /**
   * True when the active node is `ContinueNode`.
   */
  isContinueNode: boolean;
  /**
   * True when a Journey action is currently in-flight.
   */
  loading: boolean;
  /**
   * Normalized callback fields for the active node.
   */
  fields: JourneyNormalizedField[];
  /**
   * True when `DeviceProfileCallback` is present.
   */
  hasDeviceProfileCallback: boolean;
  /**
   * True when `PollingWaitCallback` is present.
   */
  hasPollingWaitCallback: boolean;
  /**
   * True when `SuspendedTextOutputCallback` is present.
   */
  hasSuspendedCallback: boolean;
  /**
   * True when at least one callback is unsupported.
   */
  hasUnsupportedCallbacks: boolean;
  /**
   * Polling wait time resolved from callback payload.
   */
  pollingWaitMs: number | null;
};

/**
 * Evaluated automation policy for a `ContinueNode`.
 */
export type ContinueNodeAutomationPolicy = {
  /**
   * True when at least one callback requires user input before submit.
   */
  hasBlockingUserInput: boolean;
  /**
   * True when at least one callback is auto-capable.
   */
  hasAutoCapableCallback: boolean;
  /**
   * True when at least one callback still requires integration.
   */
  hasIntegrationRequiredCallback: boolean;
  /**
   * True when sample app should auto-submit callback input.
   */
  canAutoSubmit: boolean;
  /**
   * True when sample app should schedule polling auto-next.
   */
  canAutoPoll: boolean;
  /**
   * True when sample app should call `next({})` after successful device profile collection.
   */
  canAutoSubmitAfterDeviceProfile: boolean;
  /**
   * Polling delay that should be used for timer scheduling.
   */
  pollingDelayMs: number;
};

/**
 * Resolves sample-app automation decisions for `ContinueNode` handling.
 *
 * @param input - Policy evaluation input.
 * @returns Evaluated automation policy.
 */
export function resolveContinueNodeAutomationPolicy(
  input: ContinueNodeAutomationPolicyInput,
): ContinueNodeAutomationPolicy {
  const {
    isContinueNode,
    loading,
    fields,
    hasDeviceProfileCallback,
    hasPollingWaitCallback,
    hasSuspendedCallback,
    hasUnsupportedCallbacks,
    pollingWaitMs,
  } = input;

  // When polling is active, ConfirmationCallback is a cancel escape hatch — not a
  // blocking user choice. Exclude it from the blocking check so auto-poll proceeds.
  const hasBlockingUserInput = fields.some(
    field =>
      field.requiresUserInput &&
      !(hasPollingWaitCallback && field.ref.type === 'ConfirmationCallback'),
  );
  const hasAutoCapableCallback = fields.some(
    field => field.executionMode === 'auto_capable',
  );
  const hasIntegrationRequiredCallback = fields.some(
    field => field.executionMode === 'integration_required',
  );

  const canAutoSubmit =
    isContinueNode &&
    !loading &&
    hasAutoCapableCallback &&
    !hasBlockingUserInput &&
    !hasUnsupportedCallbacks &&
    !hasIntegrationRequiredCallback &&
    !hasDeviceProfileCallback &&
    !hasPollingWaitCallback &&
    !hasSuspendedCallback;

  const canAutoPoll =
    isContinueNode &&
    !loading &&
    hasPollingWaitCallback &&
    !hasBlockingUserInput &&
    !hasUnsupportedCallbacks &&
    !hasIntegrationRequiredCallback;

  const canAutoSubmitAfterDeviceProfile =
    !hasBlockingUserInput && !hasPollingWaitCallback;

  return {
    hasBlockingUserInput,
    hasAutoCapableCallback,
    hasIntegrationRequiredCallback,
    canAutoSubmit,
    canAutoPoll,
    canAutoSubmitAfterDeviceProfile,
    pollingDelayMs: Math.max(
      500,
      pollingWaitMs ?? DEFAULT_AUTO_POLLING_WAIT_MS,
    ),
  };
}
