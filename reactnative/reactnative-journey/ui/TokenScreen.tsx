/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useJourney } from '@ping-identity/rn-journey';
import { useDeviceAuthGrant } from '@ping-identity/rn-oidc';
import { PingError } from '@ping-identity/rn-types';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import AuthSourceTabs from './components/molecules/AuthSourceTabs';
import TokenJourneyPanel from './token/components/organisms/TokenJourneyPanel';
import TokenDeviceAuthPanel from './token/components/organisms/TokenDeviceAuthPanel';

const TOKEN_TABS = ['Journey', 'Auth Grant'] as const;

type TokenTab = (typeof TOKEN_TABS)[number];

const getEmptyMessage = (tab: TokenTab): string => {
  switch (tab) {
    case 'Journey':
      return 'No Journey token information is available';
    case 'Auth Grant':
      return 'No Auth Grant token information is available';
  }
};

const JOURNEY_AUTH_REQUIRED_MESSAGE =
  'No authenticated Journey token state found. Complete Journey login first, then tap AccessToken.';

const authRequiredMessageFor = (_tab: TokenTab): string =>
  JOURNEY_AUTH_REQUIRED_MESSAGE;

/**
 * Renders token operations by auth source with tabbed navigation.
 *
 * @returns Token screen element.
 */
export default function TokenScreen(): React.ReactElement {
  const [activeTab, setActiveTab] = useState<TokenTab>('Journey');
  const [tokenOutputByTab, setTokenOutputByTab] = useState<
    Record<TokenTab, string>
  >({
    Journey: getEmptyMessage('Journey'),
    'Auth Grant': getEmptyMessage('Auth Grant'),
  });
  const [loading, setLoading] = useState<boolean>(false);

  const [, journeyActions] = useJourney();
  const [, deviceActions] = useDeviceAuthGrant();

  const setActiveTabOutput = useCallback(
    (value: string): void => {
      setTokenOutputByTab(previous => ({ ...previous, [activeTab]: value }));
    },
    [activeTab],
  );

  const handleAccessToken = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      if (activeTab === 'Journey') {
        const session = await journeyActions.user();
        if (!session) {
          setActiveTabOutput(getEmptyMessage('Journey'));
          return;
        }
        setActiveTabOutput(JSON.stringify(session, null, 2));
        return;
      }

      const tokens = await deviceActions.token();
      setActiveTabOutput(
        tokens
          ? JSON.stringify(tokens, null, 2)
          : getEmptyMessage('Auth Grant'),
      );
    } catch (error) {
      if (
        error instanceof PingError &&
        (error.message.includes('No AuthCode is available') ||
          error.message.includes('Please start Journey to authenticate'))
      ) {
        setActiveTabOutput(authRequiredMessageFor(activeTab));
      } else {
        setActiveTabOutput(formatError(error));
      }
    } finally {
      setLoading(false);
    }
  }, [activeTab, deviceActions, journeyActions, setActiveTabOutput]);

  const handleClear = useCallback((): void => {
    setActiveTabOutput(getEmptyMessage(activeTab));
  }, [activeTab, setActiveTabOutput]);

  const handleRefresh = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      if (activeTab === 'Journey') {
        const session = await journeyActions.refresh();
        if (!session) {
          setActiveTabOutput(getEmptyMessage('Journey'));
          return;
        }
        setActiveTabOutput(JSON.stringify(session, null, 2));
        return;
      }

      const tokens = await deviceActions.refresh();
      setActiveTabOutput(
        tokens
          ? JSON.stringify(tokens, null, 2)
          : getEmptyMessage('Auth Grant'),
      );
    } catch (error) {
      if (
        error instanceof PingError &&
        (error.message.includes('No AuthCode is available') ||
          error.message.includes('Please start Journey to authenticate'))
      ) {
        setActiveTabOutput(authRequiredMessageFor(activeTab));
      } else {
        setActiveTabOutput(formatError(error));
      }
    } finally {
      setLoading(false);
    }
  }, [activeTab, deviceActions, journeyActions, setActiveTabOutput]);

  const handleRevoke = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      if (activeTab === 'Auth Grant') {
        await deviceActions.revoke();
        setActiveTabOutput(getEmptyMessage('Auth Grant'));
        return;
      }

      await journeyActions.revoke();
      const session = await journeyActions.user();
      if (session) {
        setActiveTabOutput(
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
        setActiveTabOutput(getEmptyMessage('Journey'));
      }
    } catch (error) {
      setActiveTabOutput(formatError(error));
    } finally {
      setLoading(false);
    }
  }, [activeTab, deviceActions, journeyActions, setActiveTabOutput]);

  return (
    <View style={commonStyles.userProfileContainer}>
      <AuthSourceTabs
        tabs={TOKEN_TABS}
        activeTab={activeTab}
        onTabChange={setActiveTab}
      />

      <ScrollView
        style={commonStyles.userProfileBody}
        contentContainerStyle={commonStyles.container}
        nestedScrollEnabled
      >
        {activeTab === 'Journey' ? (
          <TokenJourneyPanel
            tokenOutput={tokenOutputByTab.Journey}
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
        ) : (
          <TokenDeviceAuthPanel
            tokenOutput={tokenOutputByTab['Auth Grant']}
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
        )}
      </ScrollView>
    </View>
  );
}
