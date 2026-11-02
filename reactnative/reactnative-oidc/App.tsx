/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useMemo, useRef } from 'react';
import {
  NavigationContainer,
  type NavigationState,
  type PartialState,
} from '@react-navigation/native';
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
import {
  createPresetProfiles,
  sampleAppClientProfiles as bundledProfiles,
  type SampleAppClientProfile,
} from './src/clients';
import { useCustomConfigs } from './src/config/useCustomConfigs';
import type { ConfigEditorParams } from './src/config/useConfigActions';
import ConfigEditorScreen from './ui/ConfigEditorScreen';
import { useStoredSelection } from './src/config/useStoredSelection';
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
  ConfigEditor: ConfigEditorParams;
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
 * Provider key that changes when a custom config is edited, so the provider
 * rebuilds against the updated client.
 *
 * @param profile Selected profile, if any.
 * @returns Stable key for the profile's current configuration.
 */
function profileRevision(
  profile: SampleAppClientProfile | null | undefined,
): string {
  return profile
    ? `${profile.key}:${JSON.stringify(profile.unifiedConfig ?? '')}`
    : 'none';
}

/**
 * Releases the lazily built clients of a preset profile when it is deselected.
 *
 * @param profile Profile that was just deselected.
 */
function disposeProfileClients(
  profile: SampleAppClientProfile | null | undefined,
): void {
  if (!profile?.dispose) {
    return;
  }
  profile.dispose().catch((error: unknown) => {
    console.warn(`Failed to dispose profile '${profile.key}'`, error);
  });
}

/**
 * Root sample app component that wires navigation and initializes demo clients.
 *
 * ## Structure
 *
 * 1. **Profile selection** — `sampleAppClientProfiles` (defined in `src/clients.ts`) lists
 *    OIDC client configurations: the bundled
 *    `assets/configs/*.json` presets plus custom configs. The active profile is stored as `selectedOidcProfileKey`
 *    and restored from AsyncStorage on start; with no stored selection the OIDC route shows
 *    Configuration Required.
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
  // Providers below are re-keyed when the selected config changes; keeping the
  // navigation state here restores the user's position after the remount.
  const navigationState = useRef<
    NavigationState | PartialState<NavigationState> | undefined
  >(undefined);
  // Dedicated browser logger keeps browser diagnostics separate from global SDK logging.
  const browserLogger = useMemo(() => logger({ level: 'debug' }), []);
  const {
    key: selectedOidcProfileKey,
    select: setSelectedOidcProfileKey,
    restored: oidcSelectionRestored,
  } = useStoredSelection('selectedOidcProfileKey');

  const customConfigs = useCustomConfigs();
  const oidcProfiles = useMemo(
    () => [
      ...bundledProfiles,
      ...customConfigs.presets.flatMap(createPresetProfiles),
    ],
    [customConfigs.presets],
  );

  const selectedOidcProfile = useMemo(
    () =>
      oidcProfiles.find(profile => profile.key === selectedOidcProfileKey) ??
      null,
    [oidcProfiles, selectedOidcProfileKey],
  );

  const oidcProviderClient =
    selectedOidcProfile?.oidcClient ?? oidcProfiles[0]?.oidcClient;

  useEffect(
    () => () => disposeProfileClients(selectedOidcProfile),
    [selectedOidcProfile],
  );

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

  if (!oidcSelectionRestored || !customConfigs.restored) {
    return null;
  }

  const selectedConfigName = `OIDC: ${selectedOidcProfile?.name ?? 'None'}`;

  if (!oidcProviderClient) {
    return (
      <Text>
        No OIDC configuration is available. Add a JSON file to assets/configs.
      </Text>
    );
  }

  return (
    // OIDC hooks resolve the client from this context.
    <OidcProvider
      key={profileRevision(selectedOidcProfile)}
      client={oidcProviderClient}
    >
      <NavigationContainer
        initialState={navigationState.current}
        onStateChange={state => {
          navigationState.current = state;
        }}
      >
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
                profiles={oidcProfiles}
                selectedOidcProfileKey={selectedOidcProfileKey}
                onSelectOidcProfile={setSelectedOidcProfileKey}
                onAddCustomConfig={customConfigs.add}
                onDeleteCustomConfig={customConfigs.remove}
              />
            )}
          </Stack.Screen>
          <Stack.Screen
            name="ConfigEditor"
            options={{ title: 'Configuration' }}
          >
            {props => (
              <ConfigEditorScreen
                {...props}
                onAdd={customConfigs.add}
                onUpdate={customConfigs.update}
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
