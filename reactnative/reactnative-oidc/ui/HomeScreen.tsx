/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React from 'react';
import { View, Text, Image, ScrollView } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { commonStyles } from '../src/styles/common';
import { RootStackParamList } from '../App';
import HomeMenuRow, {
  type HomeMenuItem,
} from './components/molecules/HomeMenuRow';

type HomeScreenNavProp = NativeStackNavigationProp<RootStackParamList, 'Home'>;
type Props = {
  navigation: HomeScreenNavProp;
  selectedConfigName: string;
};
type HomeScreenMenuItem = Omit<HomeMenuItem, 'onPress' | 'disabled'> & {
  screen?: keyof RootStackParamList;
};

/**
 * Home screen with entry points for the OIDC demo flow.
 */
export default function HomeScreen({
  navigation,
  selectedConfigName: _selectedConfigName,
}: Props) {
  const runtime = globalThis as {
    RN$Bridgeless?: boolean;
    nativeFabricUIManager?: unknown;
  };
  const isNewArchEnabled =
    runtime.RN$Bridgeless === true || runtime.nativeFabricUIManager != null;

  const authenticationItems: HomeScreenMenuItem[] = [
    {
      title: 'OIDC Login',
      subtitle: 'OpenID Connect Flow',
      icon: 'lock',
      screen: 'Oidc',
    },
  ];

  const userManagementItems: HomeScreenMenuItem[] = [
    {
      title: 'Access Token',
      subtitle: 'View current token',
      icon: 'token',
      screen: 'Token',
    },
    {
      title: 'User Profile',
      subtitle: 'View user details',
      icon: 'account-circle',
      screen: 'UserProfile',
    },
    {
      title: 'Logout',
      subtitle: 'End session',
      icon: 'logout',
      screen: 'Logout',
    },
  ];

  const renderMenuItem = (item: HomeScreenMenuItem): React.ReactElement => {
    const isDisabled = item.comingSoon || !item.screen;

    return (
      <HomeMenuRow
        key={item.title}
        title={item.title}
        subtitle={item.subtitle}
        icon={item.icon}
        comingSoon={item.comingSoon}
        disabled={isDisabled}
        onPress={() =>
          navigation.navigate(item.screen as keyof RootStackParamList)
        }
      />
    );
  };

  return (
    <View style={commonStyles.homeContainer}>
      <View style={commonStyles.homeHeader}>
        <Image
          // eslint-disable-next-line @typescript-eslint/no-require-imports
          source={require('../assets/ping_logo.png')}
          style={commonStyles.homeHeaderLogo}
        />
        <Text style={commonStyles.homeHeaderTitle}>
          React Native Sample App
        </Text>
        <Text style={commonStyles.homeHeaderSubtitle}>Version 1.0</Text>
      </View>

      <ScrollView
        style={commonStyles.homeBody}
        contentContainerStyle={commonStyles.homeBodyContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={commonStyles.homeList}>
          <Text style={commonStyles.homeSectionTitle}>AUTHENTICATION</Text>
          {authenticationItems.map(renderMenuItem)}

          <Text style={commonStyles.homeSectionTitle}>USER MANAGEMENT</Text>
          {userManagementItems.map(renderMenuItem)}

          <Text style={commonStyles.homeSectionTitle}>SETUP</Text>
          <HomeMenuRow
            title="Configuration"
            subtitle="Edit Configuration"
            icon="settings"
            onPress={() => navigation.navigate('Configuration')}
          />

          <View style={commonStyles.homeFooter}>
            <View style={commonStyles.homeFooterLabelRow}>
              <Text style={commonStyles.homeFooterText}>
                React Native Unified SDK
              </Text>
              <Text style={commonStyles.homeFooterText}>
                {`New Arch: ${isNewArchEnabled ? 'Enabled' : 'Disabled'}`}
              </Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}
