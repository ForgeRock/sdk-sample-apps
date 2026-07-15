/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useJourney } from '@ping-identity/rn-journey';
import { PingError } from '@ping-identity/rn-types';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import TokenJourneyPanel from './token/components/organisms/TokenJourneyPanel';

const EMPTY_MESSAGE = 'No Journey token information is available';

const JOURNEY_AUTH_REQUIRED_MESSAGE =
  'No authenticated Journey token state found. Complete Journey login first, then tap AccessToken.';

/**
 * Renders Journey token operations.
 *
 * @returns Token screen element.
 */
export default function TokenScreen(): React.ReactElement {
  const [tokenOutput, setTokenOutput] = useState<string>(EMPTY_MESSAGE);
  const [loading, setLoading] = useState<boolean>(false);

  const [, journeyActions] = useJourney();

  const handleAccessToken = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      const session = await journeyActions.user();
      if (!session) {
        setTokenOutput(EMPTY_MESSAGE);
        return;
      }
      setTokenOutput(JSON.stringify(session, null, 2));
    } catch (error) {
      if (
        error instanceof PingError &&
        (error.message.includes('No AuthCode is available') ||
          error.message.includes('Please start Journey to authenticate'))
      ) {
        setTokenOutput(JOURNEY_AUTH_REQUIRED_MESSAGE);
      } else {
        setTokenOutput(formatError(error));
      }
    } finally {
      setLoading(false);
    }
  }, [journeyActions]);

  const handleClear = useCallback((): void => {
    setTokenOutput(EMPTY_MESSAGE);
  }, []);

  const handleRefresh = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      const session = await journeyActions.refresh();
      if (!session) {
        setTokenOutput(EMPTY_MESSAGE);
        return;
      }
      setTokenOutput(JSON.stringify(session, null, 2));
    } catch (error) {
      if (
        error instanceof PingError &&
        (error.message.includes('No AuthCode is available') ||
          error.message.includes('Please start Journey to authenticate'))
      ) {
        setTokenOutput(JOURNEY_AUTH_REQUIRED_MESSAGE);
      } else {
        setTokenOutput(formatError(error));
      }
    } finally {
      setLoading(false);
    }
  }, [journeyActions]);

  const handleRevoke = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      await journeyActions.revoke();
      const session = await journeyActions.user();
      if (session) {
        setTokenOutput(
          JSON.stringify(
            {
              note: 'Revoke completed, but Journey user session is still active.',
              session,
            },
            null,
            2,
          ),
        );
      } else {
        setTokenOutput(EMPTY_MESSAGE);
      }
    } catch (error) {
      setTokenOutput(formatError(error));
    } finally {
      setLoading(false);
    }
  }, [journeyActions]);

  return (
    <View style={commonStyles.userProfileContainer}>
      <ScrollView
        style={commonStyles.userProfileBody}
        contentContainerStyle={commonStyles.container}
        nestedScrollEnabled
      >
        <TokenJourneyPanel
          tokenOutput={tokenOutput}
          loading={loading}
          onAccessToken={() => {
            void handleAccessToken();
          }}
          onRefresh={() => {
            void handleRefresh();
          }}
          onRevoke={() => {
            void handleRevoke();
          }}
          onClear={handleClear}
        />
      </ScrollView>
    </View>
  );
}
