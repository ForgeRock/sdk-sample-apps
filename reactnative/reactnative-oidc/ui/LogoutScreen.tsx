/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useOidc } from '@ping-identity/rn-oidc';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import AsyncActionButton from './components/molecules/AsyncActionButton';
import CardSection from './components/molecules/CardSection';
import EmptyStateCard from './components/molecules/EmptyStateCard';

/**
 * Renders session logout controls for the OIDC Web session.
 *
 * @returns Logout screen element.
 */
export default function LogoutScreen(): React.ReactElement {
  const [busyOidc, setBusyOidc] = useState<boolean>(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [oidcState, oidcActions] = useOidc();

  const refreshSessionState = useCallback(async (): Promise<void> => {
    try {
      await oidcActions.restore();
    } catch {
      // OIDC hook state already captures typed errors for UI display.
    }
  }, [oidcActions]);

  useFocusEffect(
    useCallback(() => {
      void refreshSessionState();
      return undefined;
    }, [refreshSessionState]),
  );

  const handleLogoutOidc = useCallback(async (): Promise<void> => {
    setBusyOidc(true);
    setErrorMessage(null);
    setStatusMessage(null);
    try {
      if (!oidcState.isAuthenticated) {
        setStatusMessage('No active OIDC Web session found.');
        return;
      }
      await oidcActions.logout();
      setStatusMessage('OIDC Web session logged out.');
    } catch (error) {
      setErrorMessage(formatError(error));
    } finally {
      setBusyOidc(false);
      await refreshSessionState();
    }
  }, [oidcActions, oidcState.isAuthenticated, refreshSessionState]);

  return (
    <ScrollView contentContainerStyle={commonStyles.container}>
      {oidcState.isAuthenticated ? (
        <CardSection title="OIDC Web Session">
          <Text style={commonStyles.codeText}>
            Logout from OIDC Web authentication
          </Text>
          <Text style={commonStyles.codeText}>Status: Active</Text>
          <AsyncActionButton
            label="Logout from OIDC Web Session"
            onPress={() => {
              void handleLogoutOidc();
            }}
            loading={busyOidc}
            disabled={busyOidc}
          />
        </CardSection>
      ) : (
        <EmptyStateCard
          title="No Active Sessions"
          message="You are not logged in to any session"
        />
      )}
      {statusMessage ? (
        <Text style={commonStyles.textSuccess}>{statusMessage}</Text>
      ) : null}
      {errorMessage ? (
        <Text style={commonStyles.textError}>{errorMessage}</Text>
      ) : null}
    </ScrollView>
  );
}
