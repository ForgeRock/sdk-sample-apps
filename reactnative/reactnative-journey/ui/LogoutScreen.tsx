/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { useJourney } from '@ping-identity/rn-journey';
import { useDeviceAuthGrant } from '@ping-identity/rn-oidc';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import AsyncActionButton from './components/molecules/AsyncActionButton';
import CardSection from './components/molecules/CardSection';
import EmptyStateCard from './components/molecules/EmptyStateCard';

/**
 * Renders session logout controls for Journey and Auth Grant sessions.
 *
 * @returns Logout screen element.
 */
export default function LogoutScreen(): React.ReactElement {
  const [busyAll, setBusyAll] = useState<boolean>(false);
  const [busyJourney, setBusyJourney] = useState<boolean>(false);
  const [busyAuthGrant, setBusyAuthGrant] = useState<boolean>(false);
  const [journeyActive, setJourneyActive] = useState<boolean>(false);
  const [authGrantActive, setAuthGrantActive] = useState<boolean>(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [, journeyActions] = useJourney();
  const [, deviceActions] = useDeviceAuthGrant();

  const refreshSessionState = useCallback(async (): Promise<void> => {
    try {
      const journeySession = await journeyActions.user();
      setJourneyActive(Boolean(journeySession));
    } catch {
      setJourneyActive(false);
    }

    try {
      const authGrantUser = await deviceActions.restore();
      setAuthGrantActive(Boolean(authGrantUser));
    } catch {
      setAuthGrantActive(false);
    }
  }, [deviceActions, journeyActions]);

  useFocusEffect(
    useCallback(() => {
      void refreshSessionState();
      return undefined;
    }, [refreshSessionState]),
  );

  const handleLogoutAll = useCallback(async (): Promise<void> => {
    setBusyAll(true);
    setErrorMessage(null);
    setStatusMessage(null);
    const errors: string[] = [];

    try {
      await journeyActions.logoutUser();
    } catch (error) {
      errors.push(formatError(error));
    }

    try {
      await deviceActions.logout();
    } catch (error) {
      errors.push(formatError(error));
    }

    await refreshSessionState();
    setBusyAll(false);

    if (errors.length > 0) {
      setErrorMessage(errors.join('\n'));
      return;
    }
  }, [deviceActions, journeyActions, refreshSessionState]);

  const handleLogoutAuthGrant = useCallback(async (): Promise<void> => {
    setBusyAuthGrant(true);
    setErrorMessage(null);
    setStatusMessage(null);
    try {
      const loggedOut = await deviceActions.logout();
      setStatusMessage(
        loggedOut
          ? 'Auth Grant session logged out.'
          : 'No active Auth Grant session found.',
      );
    } catch (error) {
      setErrorMessage(formatError(error));
    } finally {
      setBusyAuthGrant(false);
      await refreshSessionState();
    }
  }, [deviceActions, refreshSessionState]);

  const handleLogoutJourney = useCallback(async (): Promise<void> => {
    setBusyJourney(true);
    setErrorMessage(null);
    setStatusMessage(null);
    try {
      await journeyActions.logoutUser();
      setStatusMessage('Journey session logged out.');
    } catch (error) {
      setErrorMessage(formatError(error));
    } finally {
      setBusyJourney(false);
      await refreshSessionState();
    }
  }, [journeyActions, refreshSessionState]);

  const disabled = busyAll || busyJourney || busyAuthGrant;
  const hasAnySession = journeyActive || authGrantActive;

  return (
    <ScrollView contentContainerStyle={commonStyles.container}>
      <CardSection
        title="Active Sessions"
        subtitle="Select a session to logout"
      >
        {hasAnySession ? (
          <AsyncActionButton
            label="Logout All Sessions"
            onPress={() => {
              void handleLogoutAll();
            }}
            loading={busyAll}
            disabled={disabled}
          />
        ) : (
          <AsyncActionButton
            label="No Active Sessions"
            onPress={() => {}}
            variant="secondary"
            disabled
          />
        )}
      </CardSection>

      {journeyActive ? (
        <CardSection title="Journey Session">
          <Text style={commonStyles.codeText}>
            Logout from Journey authentication
          </Text>
          <Text style={commonStyles.codeText}>Status: Active</Text>
          <AsyncActionButton
            label="Logout from Journey Session"
            onPress={() => {
              void handleLogoutJourney();
            }}
            loading={busyJourney}
            disabled={disabled}
          />
        </CardSection>
      ) : null}

      {authGrantActive ? (
        <CardSection title="Auth Grant Session">
          <Text style={commonStyles.codeText}>
            Logout from Device Authorization Grant authentication
          </Text>
          <Text style={commonStyles.codeText}>Status: Active</Text>
          <AsyncActionButton
            label="Logout from Auth Grant Session"
            onPress={() => void handleLogoutAuthGrant()}
            loading={busyAuthGrant}
            disabled={disabled}
          />
        </CardSection>
      ) : null}

      {!hasAnySession ? (
        <EmptyStateCard
          title="No Active Sessions"
          message="You are not logged in to any session"
        />
      ) : null}
      {statusMessage ? (
        <Text style={commonStyles.textSuccess}>{statusMessage}</Text>
      ) : null}
      {errorMessage ? (
        <Text style={commonStyles.textError}>{errorMessage}</Text>
      ) : null}
    </ScrollView>
  );
}
