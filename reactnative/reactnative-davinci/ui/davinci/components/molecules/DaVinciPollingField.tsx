/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Text, View } from 'react-native';
import type {
  PollingCollector,
  PollingStatus,
} from '@ping-identity/rn-davinci';
import { colors } from '../../../../src/styles/colors';
import { davinciFieldStyles } from '../../../../src/styles/davinciStyles';
import type { DaVinciCollectorRendererProps } from './types';

/**
 * Resolves a human-readable message for a {@link PollingStatus} tick.
 *
 * @param status Streamed polling status.
 * @returns User-facing status message.
 */
function describeStatus(status: PollingStatus): string {
  switch (status.status) {
    case 'continue':
      return `Waiting for approval (${status.retryCount}/${status.maxRetries})...`;
    case 'complete':
      return 'Approved.';
    case 'timedOut':
      return 'Polling timed out.';
    case 'expired':
      return 'Polling expired.';
    case 'error':
      return status.error.message;
    default:
      return '';
  }
}

/**
 * Renders a {@link PollingCollector} by subscribing to `pollStatus` on mount
 * and displaying the latest streamed status until a terminal tick arrives.
 *
 * @remarks
 * Does not call `next()` itself — the controller's `onPollStatus` callback
 * is expected to advance the flow once a terminal status is observed.
 *
 * @param props Renderer props.
 * @returns Polling status field element.
 */
export default function DaVinciPollingField(
  props: DaVinciCollectorRendererProps,
): React.ReactElement {
  const { collector, onPollStatus } = props;
  const pollingCollector = collector as PollingCollector;
  const [status, setStatus] = useState<PollingStatus | null>(null);

  useEffect(() => {
    let unsubscribe: (() => void) | undefined;
    let cancelled = false;

    onPollStatus(pollingCollector, nextStatus => {
      if (!cancelled) {
        setStatus(nextStatus);
      }
    })
      .then(unsub => {
        if (cancelled) {
          unsub();
          return;
        }
        unsubscribe = unsub;
      })
      .catch(() => {
        // Surfaced via the panel's shared `error` state.
      });

    return () => {
      cancelled = true;
      unsubscribe?.();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [pollingCollector.key]);

  const isTerminal = status !== null && status.status !== 'continue';

  return (
    <View style={davinciFieldStyles.card}>
      <View style={davinciFieldStyles.pollingStatusRow}>
        {isTerminal ? null : (
          <ActivityIndicator size="small" color={colors.primary} />
        )}
        <Text style={davinciFieldStyles.pollingStatusText}>
          {status ? describeStatus(status) : 'Waiting for approval...'}
        </Text>
      </View>
    </View>
  );
}
