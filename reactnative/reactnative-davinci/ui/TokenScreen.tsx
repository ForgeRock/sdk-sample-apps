/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useDaVinci } from '@ping-identity/rn-davinci';
import { useDeviceAuthGrant } from '@ping-identity/rn-oidc';
import { PingError } from '@ping-identity/rn-types';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import AuthSourceTabs from './components/molecules/AuthSourceTabs';
import TokenDaVinciPanel from './token/components/organisms/TokenDaVinciPanel';
import TokenDeviceAuthPanel from './token/components/organisms/TokenDeviceAuthPanel';

const TOKEN_TABS = ['DaVinci', 'Auth Grant'] as const;

type TokenTab = (typeof TOKEN_TABS)[number];

const getEmptyMessage = (tab: TokenTab): string => {
  switch (tab) {
    case 'DaVinci':
      return 'No DaVinci token information is available';
    case 'Auth Grant':
      return 'No Auth Grant token information is available';
  }
};

const DAVINCI_AUTH_REQUIRED_MESSAGE =
  'No authenticated DaVinci token state found. Complete DaVinci login first, then tap AccessToken.';

/**
 * Renders token operations by auth source with tabbed navigation.
 *
 * @returns Token screen element.
 */
export default function TokenScreen(): React.ReactElement {
  const [activeTab, setActiveTab] = useState<TokenTab>('DaVinci');
  const [tokenOutputByTab, setTokenOutputByTab] = useState<
    Record<TokenTab, string>
  >({
    DaVinci: getEmptyMessage('DaVinci'),
    'Auth Grant': getEmptyMessage('Auth Grant'),
  });
  const [loading, setLoading] = useState<boolean>(false);

  const davinciActions = useDaVinci();
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
      if (activeTab === 'DaVinci') {
        const session = await davinciActions.user();
        if (!session) {
          setActiveTabOutput(DAVINCI_AUTH_REQUIRED_MESSAGE);
          return;
        }
        setActiveTabOutput(session.accessToken);
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
        error.message.includes('No AuthCode is available')
      ) {
        setActiveTabOutput(DAVINCI_AUTH_REQUIRED_MESSAGE);
      } else {
        setActiveTabOutput(formatError(error));
      }
    } finally {
      setLoading(false);
    }
  }, [activeTab, davinciActions, deviceActions, setActiveTabOutput]);

  useFocusEffect(
    useCallback(() => {
      if (activeTab === 'DaVinci') {
        void handleAccessToken();
      }
    }, [activeTab, handleAccessToken]),
  );

  const handleClear = useCallback((): void => {
    setActiveTabOutput(getEmptyMessage(activeTab));
  }, [activeTab, setActiveTabOutput]);

  const handleRefresh = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      if (activeTab === 'DaVinci') {
        const session = await davinciActions.refresh();
        if (!session) {
          setActiveTabOutput(DAVINCI_AUTH_REQUIRED_MESSAGE);
          return;
        }
        setActiveTabOutput(session.refreshToken ?? getEmptyMessage('DaVinci'));
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
        error.message.includes('No AuthCode is available')
      ) {
        setActiveTabOutput(DAVINCI_AUTH_REQUIRED_MESSAGE);
      } else {
        setActiveTabOutput(formatError(error));
      }
    } finally {
      setLoading(false);
    }
  }, [activeTab, davinciActions, deviceActions, setActiveTabOutput]);

  const handleRevoke = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      if (activeTab === 'DaVinci') {
        const revoked = await davinciActions.revoke();
        setActiveTabOutput(
          JSON.stringify(
            {
              revoked,
              note: revoked
                ? 'DaVinci revoke completed. Re-authenticate to access tokens again.'
                : 'No active DaVinci user to revoke.',
            },
            null,
            2,
          ),
        );
        return;
      }

      await deviceActions.revoke();
      setActiveTabOutput(getEmptyMessage('Auth Grant'));
    } catch (error) {
      setActiveTabOutput(formatError(error));
    } finally {
      setLoading(false);
    }
  }, [activeTab, davinciActions, deviceActions, setActiveTabOutput]);

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
        {activeTab === 'DaVinci' ? (
          <TokenDaVinciPanel
            tokenOutput={tokenOutputByTab.DaVinci}
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
