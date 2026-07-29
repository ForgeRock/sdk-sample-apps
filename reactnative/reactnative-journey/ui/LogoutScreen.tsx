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
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import AsyncActionButton from './components/molecules/AsyncActionButton';
import CardSection from './components/molecules/CardSection';
import EmptyStateCard from './components/molecules/EmptyStateCard';

/**
 * Renders session logout controls for the Journey session.
 *
 * @returns Logout screen element.
 */
export default function LogoutScreen(): React.ReactElement {
  const [busyJourney, setBusyJourney] = useState<boolean>(false);
  const [journeyActive, setJourneyActive] = useState<boolean>(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [, journeyActions] = useJourney();

  const refreshSessionState = useCallback(async (): Promise<void> => {
    try {
      const journeySession = await journeyActions.user();
      setJourneyActive(Boolean(journeySession));
    } catch {
      setJourneyActive(false);
    }
  }, [journeyActions]);

  useFocusEffect(
    useCallback(() => {
      void refreshSessionState();
      return undefined;
    }, [refreshSessionState]),
  );

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

  return (
    <ScrollView contentContainerStyle={commonStyles.container}>
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
            disabled={busyJourney}
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
