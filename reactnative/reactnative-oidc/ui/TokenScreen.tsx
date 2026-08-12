/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useOidc } from '@ping-identity/rn-oidc';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import TokenOidcPanel from './token/components/organisms/TokenOidcPanel';

const EMPTY_MESSAGE = 'No OIDC token information is available';

/**
 * Renders OIDC token operations.
 *
 * @returns Token screen element.
 */
export default function TokenScreen(): React.ReactElement {
  const [tokenOutput, setTokenOutput] = useState<string>(EMPTY_MESSAGE);
  const [loading, setLoading] = useState<boolean>(false);

  const [, oidcActions] = useOidc();

  const handleAccessToken = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      const tokens = await oidcActions.token();
      if (!tokens) {
        setTokenOutput(EMPTY_MESSAGE);
        return;
      }
      setTokenOutput(JSON.stringify(tokens, null, 2));
    } catch (error) {
      setTokenOutput(formatError(error));
    } finally {
      setLoading(false);
    }
  }, [oidcActions]);

  const handleClear = useCallback((): void => {
    setTokenOutput(EMPTY_MESSAGE);
  }, []);

  const handleRefresh = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      const tokens = await oidcActions.refresh();
      if (!tokens) {
        setTokenOutput(EMPTY_MESSAGE);
        return;
      }
      setTokenOutput(JSON.stringify(tokens, null, 2));
    } catch (error) {
      setTokenOutput(formatError(error));
    } finally {
      setLoading(false);
    }
  }, [oidcActions]);

  const handleRevoke = useCallback(async (): Promise<void> => {
    setLoading(true);
    try {
      const revoked = await oidcActions.revoke();
      setTokenOutput(
        JSON.stringify(
          {
            revoked,
            note: revoked
              ? 'OIDC revoke completed. Re-authenticate to access tokens again.'
              : 'No active OIDC user to revoke.',
          },
          null,
          2,
        ),
      );
    } catch (error) {
      setTokenOutput(formatError(error));
    } finally {
      setLoading(false);
    }
  }, [oidcActions]);

  return (
    <View style={commonStyles.userProfileContainer}>
      <ScrollView
        style={commonStyles.userProfileBody}
        contentContainerStyle={commonStyles.container}
        nestedScrollEnabled
      >
        <TokenOidcPanel
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
