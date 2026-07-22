/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { Alert, ScrollView, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useOidc } from '@ping-identity/rn-oidc';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import UserProfileOidcPanel from './userProfile/components/organisms/UserProfileOidcPanel';

/**
 * User profile demo screen showing OIDC session state.
 *
 * @returns User profile screen element.
 */
export default function UserProfileScreen(): React.ReactElement {
  const [showRawUserInfo, setShowRawUserInfo] = useState<boolean>(false);

  const [oidcState, oidcActions] = useOidc();

  const refreshOidcSession = useCallback(async (): Promise<void> => {
    setShowRawUserInfo(false);
    try {
      const user = await oidcActions.restore();
      if (!user) {
        return;
      }
      await oidcActions.userinfo(true);
    } catch {
      // OIDC hook state already captures typed errors for UI display.
    }
  }, [oidcActions]);

  useFocusEffect(
    useCallback(() => {
      void refreshOidcSession();
      return undefined;
    }, [refreshOidcSession]),
  );

  return (
    <View style={commonStyles.userProfileContainer}>
      <ScrollView
        style={commonStyles.userProfileBody}
        contentContainerStyle={commonStyles.userProfileBodyContent}
        nestedScrollEnabled
      >
        <UserProfileOidcPanel
          loading={oidcState.isLoading}
          userInfo={oidcState.userInfo ?? null}
          hasSession={oidcState.isAuthenticated}
          error={oidcState.error?.message ?? null}
          showRawUserInfo={showRawUserInfo}
          onToggleRawUserInfo={() => setShowRawUserInfo(value => !value)}
          onStartOidc={async () => {
            try {
              await oidcActions.authorize();
              await oidcActions.userinfo(true);
            } catch (cause) {
              Alert.alert('OIDC start failed', formatError(cause));
            }
          }}
        />
      </ScrollView>
    </View>
  );
}
