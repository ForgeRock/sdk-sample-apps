/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useMemo, useState } from 'react';
import { Alert, Text, View } from 'react-native';
import type { OidcClientConfig } from '@ping-identity/rn-oidc';
import { useOidc } from '@ping-identity/rn-oidc';
import { OidcError } from '@ping-identity/rn-oidc';
import { commonStyles } from '../../../../src/styles/common';
import CardSection from '../../../components/molecules/CardSection';
import AsyncActionButton from '../../../components/molecules/AsyncActionButton';
import PayloadViewer from '../../../components/atoms/PayloadViewer';
import KeyValueList, {
  type KeyValueItem,
} from '../../../components/atoms/KeyValueList';
import OidcActionsCard from '../molecules/OidcActionsCard';

/**
 * Props for OIDC client panel.
 */
type OidcClientPanelProps = {
  /**
   * OIDC client configuration used for the panel.
   */
  clientConfig: OidcClientConfig;
};

/**
 * Renders OIDC sample operations using the shared OIDC provider state.
 *
 * @param props Panel props.
 * @returns OIDC panel element.
 */
export default function OidcClientPanel(
  props: OidcClientPanelProps,
): React.ReactElement {
  const { clientConfig } = props;
  const [state, actions] = useOidc();

  const [showRawUserInfo, setShowRawUserInfo] = useState<boolean>(false);

  const handleAuthorize = async (): Promise<void> => {
    try {
      await actions.authorize();
    } catch (cause) {
      Alert.alert(
        'Authorize failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  const handleRestore = async (): Promise<void> => {
    try {
      await actions.restore();
    } catch (cause) {
      Alert.alert(
        'Restore failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  const handleToken = async (): Promise<void> => {
    try {
      await actions.token();
    } catch (cause) {
      Alert.alert(
        'Token failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  const handleRefresh = async (): Promise<void> => {
    try {
      await actions.refresh();
    } catch (cause) {
      Alert.alert(
        'Refresh failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  const handleUserInfo = async (): Promise<void> => {
    try {
      await actions.userinfo(true);
    } catch (cause) {
      Alert.alert(
        'User info failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  const handleRevoke = async (): Promise<void> => {
    try {
      await actions.revoke();
    } catch (cause) {
      Alert.alert(
        'Revoke failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  const handleLogout = async (): Promise<void> => {
    try {
      await actions.logout();
    } catch (cause) {
      Alert.alert(
        'Logout failed',
        cause instanceof OidcError
          ? `[${cause.code}] ${cause.message}`
          : String(cause),
      );
    }
  };

  useEffect(() => {
    const restoreSession = async (): Promise<void> => {
      try {
        await actions.restore();
      } catch {
        // OIDC hook state already captures typed errors for UI display.
      }
    };
    void restoreSession();
  }, [actions]);

  const userinfoSummaryItems = useMemo<KeyValueItem[]>(() => {
    if (!state.userInfo) {
      return [];
    }
    return [
      { label: 'Name', value: String(state.userInfo.name ?? '') },
      { label: 'Given Name', value: String(state.userInfo.given_name ?? '') },
      { label: 'Family Name', value: String(state.userInfo.family_name ?? '') },
      { label: 'Email', value: String(state.userInfo.email ?? '') },
      {
        label: 'Preferred Username',
        value: String(state.userInfo.preferred_username ?? ''),
      },
      { label: 'Sub', value: String(state.userInfo.sub ?? '') },
    ];
  }, [state.userInfo]);

  return (
    <>
      <OidcActionsCard
        loading={state.isLoading}
        isAuthenticated={state.isAuthenticated}
        onAuthorize={handleAuthorize}
        onToken={handleToken}
        onRefresh={handleRefresh}
        onUserinfo={handleUserInfo}
        onRevoke={handleRevoke}
        onLogout={handleLogout}
      />

      <CardSection title="Summary">
        <Text style={commonStyles.codeText}>
          {state.isAuthenticated ? 'Authenticated' : 'Not authenticated'}
        </Text>
        <AsyncActionButton
          label="Restore Session"
          variant="secondary"
          onPress={handleRestore}
          loading={state.isLoading}
        />

        {state.userInfo ? (
          <View style={commonStyles.codeBox}>
            <Text style={commonStyles.codeTitle}>Userinfo Summary</Text>
            <KeyValueList
              items={userinfoSummaryItems}
              textStyle={commonStyles.codeText}
            />
            <AsyncActionButton
              label={
                showRawUserInfo ? 'Hide Raw User Info' : 'Show Raw User Info'
              }
              variant="secondary"
              onPress={() => setShowRawUserInfo(previous => !previous)}
            />
            {showRawUserInfo ? (
              <PayloadViewer
                payload={JSON.stringify(state.userInfo, null, 2)}
              />
            ) : null}
          </View>
        ) : null}
      </CardSection>

      {state.tokens ? (
        <CardSection title="Tokens">
          <PayloadViewer payload={JSON.stringify(state.tokens, null, 2)} />
        </CardSection>
      ) : null}

      {state.error ? (
        <CardSection title="Error">
          <PayloadViewer payload={JSON.stringify(state.error, null, 2)} />
        </CardSection>
      ) : null}

      <CardSection title="Client Config">
        <PayloadViewer payload={JSON.stringify(clientConfig, null, 2)} />
      </CardSection>
    </>
  );
}
