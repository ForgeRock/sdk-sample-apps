/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useMemo, useState } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Pressable, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import HomeScreen from './ui/HomeScreen';
import ConfigurationScreen from './ui/ConfigurationScreen';
import OidcScreen from './ui/OidcScreen';
import UserProfileScreen from './ui/UserProfileScreen';
import TokenScreen from './ui/TokenScreen';
import LogoutScreen from './ui/LogoutScreen';
import { OidcProvider } from '@ping-identity/rn-oidc';
import { sampleAppClientProfiles } from './src/clients';
import { configureBrowser } from '@ping-identity/rn-browser';
import { logger } from '@ping-identity/rn-logger';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import { colors } from './src/styles/colors';
import { commonStyles } from './src/styles/common';

/** Minimal shape required to patch `defaultProps.style` on a core RN component class. */
type ComponentWithDefaultStyle = {
  defaultProps?: {
    style?: unknown;
    [key: string]: unknown;
  };
};

/**
 * Navigation route map for the sample app's native stack.
 *
 * Each key is a screen name; the value is the params type that screen accepts
 * (`undefined` means no params).
 */
export type RootStackParamList = {
  Home: undefined;
  Configuration: undefined;
  Oidc: undefined;
  UserProfile: undefined;
  Token: undefined;
  Logout: undefined;
};

const Stack = createNativeStackNavigator<RootStackParamList>();

type RouteProps = NativeStackScreenProps<RootStackParamList>;

/**
 * Fallback screen rendered when no sample configuration has been selected.
 *
 * @param props - Stack route props.
 * @returns Configuration-required notice screen.
 */
function ConfigurationRequiredScreen(
  props: RouteProps & { message: string },
): React.ReactElement {
  const { navigation, message } = props;

  return (
    <View style={commonStyles.container}>
      <View style={commonStyles.userProfileEmptyCard}>
        <Text style={commonStyles.userProfileEmptyTitle}>
          Configuration Required
        </Text>
        <Text style={commonStyles.userProfileSubText}>{message}</Text>
        <Pressable
          style={commonStyles.buttonPrimary}
          onPress={() => navigation.navigate('Configuration')}
        >
          <Text style={commonStyles.buttonText}>Open Configuration</Text>
        </Pressable>
      </View>
    </View>
  );
}

/**
 * Root sample app component that wires navigation and initializes demo clients.
 *
 * ## Structure
 *
 * 1. **Profile selection** — `sampleAppClientProfiles` (defined in `src/clients.ts`) lists
 *    pre-built OIDC client configurations. The active profile is stored as
 *    `selectedOidcProfileKey` and defaults to `DEFAULT_SAMPLE_APP_CLIENT_PROFILE_KEY`.
 *
 * 2. **Context providers** — `OidcProvider` exposes the active client to every screen via
 *    React context so screens do not import clients directly.
 *
 * 3. **Navigation** — a `NativeStackNavigator` registers all demo screens.
 *
 * 4. **Global SDK setup** — `configureBrowser` is called once per effect cycle to set
 *    sensible defaults. The browser logger is intentionally separate from the global logger
 *    so browser diagnostics can be filtered independently.
 */
export default function App() {
  // Dedicated browser logger keeps browser diagnostics separate from global SDK logging.
  const browserLogger = useMemo(() => logger({ level: 'debug' }), []);
  const [selectedOidcProfileKey, setSelectedOidcProfileKey] = useState<
    string | null
  >(null);

  const oidcProfiles = useMemo(() => sampleAppClientProfiles, []);

  const selectedOidcProfile = useMemo(
    () =>
      oidcProfiles.find(profile => profile.key === selectedOidcProfileKey) ??
      null,
    [oidcProfiles, selectedOidcProfileKey],
  );

  const oidcProviderClient =
    selectedOidcProfile?.oidcClient ?? oidcProfiles[0]?.oidcClient;

  useEffect(() => {
    const textComponent = Text as unknown as ComponentWithDefaultStyle;
    const textDefaults = textComponent.defaultProps ?? {};
    textComponent.defaultProps = {
      ...textDefaults,
      style: [textDefaults.style, { fontFamily: 'Montserrat-Regular' }],
    };

    const textInputComponent =
      TextInput as unknown as ComponentWithDefaultStyle;
    const textInputDefaults = textInputComponent.defaultProps ?? {};
    textInputComponent.defaultProps = {
      ...textInputDefaults,
      style: [textInputDefaults.style, { fontFamily: 'Montserrat-Regular' }],
    };

    MaterialIcon.loadFont().catch((error: unknown) => {
      console.warn('Failed to load MaterialIcons font', error);
    });

    // Browser defaults used by the OIDC authorize/logout redirect flows.
    configureBrowser(
      {
        android: {
          customTabs: {
            showTitle: false,
            urlBarHidingEnabled: true,
            colorScheme: 'dark',
          },
          authTabs: {
            ephemeral: true,
            colorScheme: 'dark',
            toolbarColor: colors.browserToolbar,
            navigationBarColor: colors.browserNavigationBar,
          },
        },
      },
      {
        logger: browserLogger,
      },
    );
  }, [browserLogger]);

  const selectedConfigName = `OIDC: ${selectedOidcProfile?.name ?? 'None'}`;

  if (!oidcProviderClient) {
    return <Text>Client profiles are not configured.</Text>;
  }

  return (
    // OIDC hooks resolve the client from this context.
    <OidcProvider client={oidcProviderClient}>
      <NavigationContainer>
        <Stack.Navigator
          initialRouteName="Home"
          screenOptions={{
            headerTitleStyle: { fontFamily: 'Montserrat-Medium' },
            headerBackTitleStyle: { fontFamily: 'Montserrat-Regular' },
            headerBackButtonDisplayMode: 'minimal',
          }}
        >
          <Stack.Screen
            name="Home"
            options={{ title: 'PingIdentity Demo', headerShown: false }}
          >
            {props => (
              <HomeScreen {...props} selectedConfigName={selectedConfigName} />
            )}
          </Stack.Screen>
          <Stack.Screen
            name="Configuration"
            options={{ title: 'Configuration' }}
          >
            {props => (
              <ConfigurationScreen
                {...props}
                profiles={sampleAppClientProfiles}
                selectedOidcProfileKey={selectedOidcProfileKey}
                onSelectOidcProfile={setSelectedOidcProfileKey}
              />
            )}
          </Stack.Screen>
          <Stack.Screen name="Oidc" options={{ title: 'OIDC Demo' }}>
            {props =>
              selectedOidcProfile ? (
                <OidcScreen
                  {...props}
                  clientConfig={selectedOidcProfile.oidcClientConfig}
                />
              ) : (
                <ConfigurationRequiredScreen
                  {...props}
                  message="Please select an OIDC configuration first."
                />
              )
            }
          </Stack.Screen>
          <Stack.Screen
            name="UserProfile"
            component={UserProfileScreen}
            options={{ title: 'User Profile' }}
          />
          <Stack.Screen
            name="Token"
            component={TokenScreen}
            options={{ title: 'Token' }}
          />
          <Stack.Screen
            name="Logout"
            component={LogoutScreen}
            options={{ title: 'Logout' }}
          />
        </Stack.Navigator>
      </NavigationContainer>
    </OidcProvider>
  );
}
