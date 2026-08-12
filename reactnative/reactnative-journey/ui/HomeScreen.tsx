/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */
import React, { useEffect, useState } from 'react';
import { View, Text, Image, ScrollView } from 'react-native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { commonStyles } from '../src/styles/common';
import { RootStackParamList } from '../App';
import { getDeviceId } from '@ping-identity/rn-device-id';
import { PingError } from '@ping-identity/rn-types';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { colors } from '../src/styles/colors';
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
 * Converts device ID errors into user friendly text.
 *
 * @param error Unknown error value from native calls.
 * @returns Safe display string for the screen.
 */
function formatDeviceIdError(error: unknown): string {
  if (error instanceof PingError) {
    return `[${error.code}] ${error.message}`;
  }
  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message;
  }
  return 'Unable to fetch device ID.';
}

/**
 * Home screen with entry points for each SDK demo flow.
 */
export default function HomeScreen({
  navigation,
  selectedConfigName: _selectedConfigName,
}: Props) {
  const [deviceId, setDeviceId] = useState<string | null>(null);
  const [deviceIdError, setDeviceIdError] = useState<string | null>(null);
  const runtime = globalThis as {
    RN$Bridgeless?: boolean;
    nativeFabricUIManager?: unknown;
  };
  const isNewArchEnabled =
    runtime.RN$Bridgeless === true || runtime.nativeFabricUIManager != null;

  const authenticationItems: HomeScreenMenuItem[] = [
    {
      title: 'Journey Flow',
      subtitle: 'Test Journey Authentication',
      icon: 'map',
      screen: 'JourneyRoute',
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
      title: 'Device Management',
      subtitle: 'Manage registered devices',
      icon: 'device-hub',
      screen: 'Devices',
    },
    {
      title: 'Logout',
      subtitle: 'End session',
      icon: 'logout',
      screen: 'Logout',
    },
  ];

  const mfaItems: HomeScreenMenuItem[] = [
    {
      title: 'QR Scanner',
      subtitle: 'Scan QR code to register account',
      icon: 'qr-code-scanner',
      screen: 'QRScanner',
    },
    {
      title: 'OATH Tokens',
      subtitle: 'Manage local OATH credentials',
      icon: 'lock-clock',
      screen: 'OathTokens',
    },
    {
      title: 'Push',
      subtitle: 'Manage push authentication accounts',
      icon: 'notifications',
      screen: 'Push',
    },
    {
      title: 'Push Notifications',
      subtitle: 'View and respond to push requests',
      icon: 'notifications-active',
      screen: 'PushNotifications',
    },
  ];

  const developerToolsItems: HomeScreenMenuItem[] = [
    {
      title: 'Browser',
      subtitle: 'Test browser flow',
      icon: 'language',
      screen: 'Browser',
    },
    {
      title: 'Logger',
      subtitle: 'Test logging',
      icon: 'logo-dev',
      screen: 'Logger',
    },
    {
      title: 'Storage',
      subtitle: 'Test storage',
      icon: 'storage',
      screen: 'Storage',
    },
    {
      title: 'Device Profile',
      subtitle: 'Collect device profile data',
      icon: 'phone-android',
      screen: 'DeviceProfile',
    },
    {
      title: 'Binding Keys',
      subtitle: 'Manage stored binding keys',
      icon: 'key',
      screen: 'BindingKeys',
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

  useEffect(() => {
    let isMounted = true;

    const loadDeviceIds = async (): Promise<void> => {
      try {
        const defaultId = await getDeviceId();
        if (isMounted) setDeviceId(defaultId);
      } catch (err) {
        if (isMounted) {
          setDeviceIdError(formatDeviceIdError(err));
        }
      }
    };

    loadDeviceIds();

    return () => {
      isMounted = false;
    };
  }, []);

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

          <Text style={commonStyles.homeSectionTitle}>MFA</Text>
          {mfaItems.map(renderMenuItem)}

          <Text style={commonStyles.homeSectionTitle}>DEVELOPER TOOLS</Text>
          {developerToolsItems.map(renderMenuItem)}

          <Text style={commonStyles.homeSectionTitle}>SETUP</Text>
          <HomeMenuRow
            title="Configuration"
            subtitle="Edit Configuration"
            icon="settings"
            onPress={() => navigation.navigate('Configuration')}
          />

          <View style={commonStyles.homeFooter}>
            <View style={commonStyles.deviceIdCard}>
              <View style={commonStyles.deviceIdHeaderRow}>
                <MaterialIcon
                  name="smartphone"
                  size={30}
                  color={colors.iconBody}
                />
                <Text style={commonStyles.deviceIdTitle}>Device ID</Text>
                {!deviceIdError ? (
                  <Text style={commonStyles.deviceIdSecuredText}>Secured</Text>
                ) : null}
              </View>
              <View style={commonStyles.deviceIdDivider} />
              {deviceIdError ? (
                <Text style={commonStyles.deviceIdErrorText}>
                  {deviceIdError}
                </Text>
              ) : (
                <Text style={commonStyles.deviceIdValueText}>
                  {deviceId ?? 'Loading...'}
                </Text>
              )}
            </View>
            {deviceIdError ? (
              <Text style={commonStyles.deviceIdText}>
                Device ID could not be resolved.
              </Text>
            ) : null}
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
