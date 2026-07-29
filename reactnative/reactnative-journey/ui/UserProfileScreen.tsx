/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useCallback, useState } from 'react';
import { ScrollView, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { useJourney, type JourneyUserSession } from '@ping-identity/rn-journey';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import { RootStackParamList } from '../App';
import UserProfileJourneyPanel from './userProfile/components/organisms/UserProfileJourneyPanel';

type UserProfileNavigationProp = NativeStackNavigationProp<
  RootStackParamList,
  'UserProfile'
>;

type Props = {
  navigation: UserProfileNavigationProp;
};

/**
 * User profile demo screen showing Journey session state.
 *
 * @param props Screen props.
 * @param props.navigation Stack navigation controller.
 * @returns User profile screen element.
 */
export default function UserProfileScreen({
  navigation,
}: Props): React.ReactElement {
  const [journeySession, setJourneySession] =
    useState<JourneyUserSession | null>(null);
  const [journeyLoading, setJourneyLoading] = useState<boolean>(false);
  const [journeyError, setJourneyError] = useState<string | null>(null);
  const [showRawJourneyUserInfo, setShowRawJourneyUserInfo] =
    useState<boolean>(false);

  const [, journeyActions] = useJourney();

  const refreshJourneySession = useCallback(async (): Promise<void> => {
    setJourneyLoading(true);
    setJourneyError(null);
    setShowRawJourneyUserInfo(false);
    try {
      const session = await journeyActions.user();
      if (session) {
        setJourneySession(session);
      } else {
        setJourneySession(null);
      }
    } catch (error) {
      setJourneyError(formatError(error));
      setJourneySession(null);
    } finally {
      setJourneyLoading(false);
    }
  }, [journeyActions]);

  useFocusEffect(
    useCallback(() => {
      void refreshJourneySession();
      return undefined;
    }, [refreshJourneySession]),
  );

  return (
    <View style={commonStyles.userProfileContainer}>
      <ScrollView
        style={commonStyles.userProfileBody}
        contentContainerStyle={commonStyles.userProfileBodyContent}
        nestedScrollEnabled
      >
        <UserProfileJourneyPanel
          loading={journeyLoading}
          session={journeySession}
          error={journeyError}
          showRawUserInfo={showRawJourneyUserInfo}
          onToggleRawUserInfo={() => setShowRawJourneyUserInfo(value => !value)}
          onStartJourney={() => navigation.navigate('JourneyRoute')}
        />
      </ScrollView>
    </View>
  );
}
