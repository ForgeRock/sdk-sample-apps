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
import { useDaVinci } from '@ping-identity/rn-davinci';
import { formatError } from './utils/formatError';
import { commonStyles } from '../src/styles/common';
import { RootStackParamList } from '../App';
import AuthSourceTabs from './components/molecules/AuthSourceTabs';
import UserProfileDaVinciPanel from './userProfile/components/organisms/UserProfileDaVinciPanel';
import UserProfileAuthGrantPanel from './userProfile/components/organisms/UserProfileAuthGrantPanel';
import { useDeviceAuthGrant } from '@ping-identity/rn-oidc';

type UserProfileTab = 'DaVinci' | 'Auth Grant';
const USER_PROFILE_TABS = ['DaVinci', 'Auth Grant'] as const;

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
  const [activeTab, setActiveTab] = useState<UserProfileTab>('DaVinci');
  const [showRawDavinciUserInfo, setShowRawDavinciUserInfo] =
    useState<boolean>(false);
  const [showRawAuthGrantUserInfo, setShowRawAuthGrantUserInfo] =
    useState<boolean>(false);
  const [davinciUserInfo, setDavinciUserInfo] = useState<Record<
    string,
    unknown
  > | null>(null);
  const [davinciHasSession, setDavinciHasSession] = useState<boolean>(false);
  const [davinciLoading, setDavinciLoading] = useState<boolean>(false);
  const [davinciError, setDavinciError] = useState<string | null>(null);
  const [authGrantUserInfo, setAuthGrantUserInfo] = useState<Record<
    string,
    unknown
  > | null>(null);
  const [authGrantLoading, setAuthGrantLoading] = useState(false);
  const [authGrantError, setAuthGrantError] = useState<string | null>(null);

  const davinciActions = useDaVinci();
  const [, deviceActions] = useDeviceAuthGrant();

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

  const refreshDavinciSession = useCallback(async (): Promise<void> => {
    setDavinciLoading(true);
    setDavinciError(null);
    setShowRawDavinciUserInfo(false);
    try {
      const session = await davinciActions.user();
      if (!session) {
        setDavinciHasSession(false);
        setDavinciUserInfo(null);
        return;
      }
      setDavinciHasSession(true);
      const info = await davinciActions.userinfo();
      setDavinciUserInfo(info);
    } catch (error) {
      setDavinciError(formatError(error));
      setDavinciHasSession(false);
      setDavinciUserInfo(null);
    } finally {
      setDavinciLoading(false);
    }
  }, [davinciActions]);

  useFocusEffect(
    useCallback(() => {
      if (activeTab === 'DaVinci') {
        void refreshDavinciSession();
      } else if (activeTab === 'Auth Grant') {
        void refreshAuthGrantSession();
      }
      return undefined;
    }, [activeTab, refreshDavinciSession, refreshAuthGrantSession]),
  );

  /**
   * Handles auth source tab change and clears source-specific raw toggles.
   *
   * @param tab Newly selected auth source tab.
   * @returns Void.
   */
  const handleTabChange = useCallback((tab: UserProfileTab): void => {
    setActiveTab(tab);
    if (tab !== 'DaVinci') {
      setShowRawDavinciUserInfo(false);
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

        {activeTab === 'DaVinci' ? (
          <UserProfileDaVinciPanel
            loading={davinciLoading}
            userInfo={davinciUserInfo}
            hasSession={davinciHasSession}
            error={davinciError}
            showRawUserInfo={showRawDavinciUserInfo}
            onToggleRawUserInfo={() =>
              setShowRawDavinciUserInfo(value => !value)
            }
            onStartDaVinci={() => navigation.navigate('DaVinci')}
          />
        ) : null}
      </ScrollView>
    </View>
  );
}
