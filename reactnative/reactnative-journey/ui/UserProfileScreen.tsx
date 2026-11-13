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
import { useDeviceAuthGrant } from '@ping-identity/rn-oidc';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import { RootStackParamList } from '../App';
import AuthSourceTabs from './components/molecules/AuthSourceTabs';
import UserProfileJourneyPanel from './userProfile/components/organisms/UserProfileJourneyPanel';
import UserProfileAuthGrantPanel from './userProfile/components/organisms/UserProfileAuthGrantPanel';

type UserProfileTab = 'Journey' | 'Auth Grant';
const USER_PROFILE_TABS = ['Journey', 'Auth Grant'] as const;

type UserProfileNavigationProp = NativeStackNavigationProp<
  RootStackParamList,
  'UserProfile'
>;

type Props = {
  navigation: UserProfileNavigationProp;
};

/**
 * User profile demo screen showing session state by authentication source.
 *
 * @param props Screen props.
 * @param props.navigation Stack navigation controller.
 * @returns User profile screen element.
 */
export default function UserProfileScreen({
  navigation,
}: Props): React.ReactElement {
  const [activeTab, setActiveTab] = useState<UserProfileTab>('Journey');
  const [journeySession, setJourneySession] =
    useState<JourneyUserSession | null>(null);
  const [journeyLoading, setJourneyLoading] = useState<boolean>(false);
  const [journeyError, setJourneyError] = useState<string | null>(null);
  const [showRawJourneyUserInfo, setShowRawJourneyUserInfo] =
    useState<boolean>(false);
  const [showRawAuthGrantUserInfo, setShowRawAuthGrantUserInfo] =
    useState<boolean>(false);
  const [authGrantUserInfo, setAuthGrantUserInfo] = useState<Record<
    string,
    unknown
  > | null>(null);
  const [authGrantLoading, setAuthGrantLoading] = useState(false);
  const [authGrantError, setAuthGrantError] = useState<string | null>(null);

  const [, journeyActions] = useJourney();
  const [, deviceActions] = useDeviceAuthGrant();

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

  const refreshAuthGrantSession = useCallback(async (): Promise<void> => {
    setAuthGrantLoading(true);
    setAuthGrantError(null);
    setShowRawAuthGrantUserInfo(false);
    try {
      const user = await deviceActions.restore();
      const userInfo = user ? await deviceActions.userinfo(false) : null;
      setAuthGrantUserInfo(userInfo);
    } catch (cause) {
      setAuthGrantUserInfo(null);
      setAuthGrantError(formatError(cause));
    } finally {
      setAuthGrantLoading(false);
    }
  }, [deviceActions]);

  useFocusEffect(
    useCallback(() => {
      if (activeTab === 'Journey') {
        void refreshJourneySession();
      } else if (activeTab === 'Auth Grant') {
        void refreshAuthGrantSession();
      }
      return undefined;
    }, [activeTab, refreshJourneySession, refreshAuthGrantSession]),
  );

  /**
   * Handles auth source tab change and clears source-specific raw toggles.
   *
   * @param tab Newly selected auth source tab.
   * @returns Void.
   */
  const handleTabChange = useCallback((tab: UserProfileTab): void => {
    setActiveTab(tab);
    if (tab !== 'Journey') {
      setShowRawJourneyUserInfo(false);
    }
    if (tab !== 'Auth Grant') {
      setShowRawAuthGrantUserInfo(false);
    }
  }, []);

  return (
    <View style={commonStyles.userProfileContainer}>
      <AuthSourceTabs
        tabs={USER_PROFILE_TABS}
        activeTab={activeTab}
        onTabChange={handleTabChange}
      />

      <ScrollView
        style={commonStyles.userProfileBody}
        contentContainerStyle={commonStyles.userProfileBodyContent}
        nestedScrollEnabled
      >
        {activeTab === 'Journey' ? (
          <UserProfileJourneyPanel
            loading={journeyLoading}
            session={journeySession}
            error={journeyError}
            showRawUserInfo={showRawJourneyUserInfo}
            onToggleRawUserInfo={() =>
              setShowRawJourneyUserInfo(value => !value)
            }
            onStartJourney={() => navigation.navigate('JourneyRoute')}
          />
        ) : null}

        {activeTab === 'Auth Grant' ? (
          <UserProfileAuthGrantPanel
            loading={authGrantLoading}
            userInfo={authGrantUserInfo}
            error={authGrantError}
            showRawUserInfo={showRawAuthGrantUserInfo}
            onToggleRawUserInfo={() =>
              setShowRawAuthGrantUserInfo(value => !value)
            }
            onStartAuthGrant={() => navigation.navigate('DeviceAuthorization')}
          />
        ) : null}
      </ScrollView>
    </View>
  );
}
