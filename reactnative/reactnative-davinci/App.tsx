/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useMemo, useRef, useState } from 'react';
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
import DeviceAuthorizationScreen from './ui/DeviceAuthorizationScreen';
import ApproveDeviceScreen from './ui/ApproveDeviceScreen';
import UserProfileScreen from './ui/UserProfileScreen';
import TokenScreen from './ui/TokenScreen';
import LogoutScreen from './ui/LogoutScreen';
import DaVinciScreen from './ui/DaVinciScreen';
import { DeviceAuthGrantProvider } from '@ping-identity/rn-oidc';
import { DaVinciProvider } from '@ping-identity/rn-davinci';
import {
  createPresetProfiles,
  sampleAppClientProfiles as bundledProfiles,
  unconfiguredDeviceAuthClient,
  type SampleAppClientProfile,
} from './src/clients';
import { useStoredSelection } from './src/config/useStoredSelection';
import { useCustomConfigs } from './src/config/useCustomConfigs';
import type { ConfigEditorParams } from './src/config/useConfigActions';
import ConfigEditorScreen from './ui/ConfigEditorScreen';
import { startProtect } from '@ping-identity/rn-protect';
import { logger } from '@ping-identity/rn-logger';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
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
  DeviceAuthorization: undefined;
  ApproveDevice: { verificationUri?: string } | undefined;
  UserProfile: undefined;
  Token: undefined;
  Logout: undefined;
  DaVinci: { verificationUri?: string } | undefined;
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
 * Provider key that changes when a custom config is edited, so providers
 * rebuild against the updated configuration.
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
 * Releases the lazily built clients of a JSON preset profile when it is
 * deselected.
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
 *    the bundled `assets/configs/*.json` presets and custom configs for DaVinci and the
 *    device authorization grant. Selections are restored from AsyncStorage on start; the
 *    DaVinci screens show Configuration Required until a DaVinci config is selected.
 *
 * 2. **Global SDK setup** — PingOne Protect is initialized once at startup; its readiness
 *    gates the DaVinci flow route.
 *
 * 3. **Context providers** — `DeviceAuthGrantProvider` and `DaVinciProvider` expose the
 *    active clients to every screen via React context so screens do not import clients
 *    directly.
 *
 * 4. **Navigation** — a `NativeStackNavigator` registers all demo screens.
 */
export default function App() {
  // Providers below are re-keyed when the selected config changes; keeping the
  // navigation state here restores the user's position after the remount.
  const navigationState = useRef<
    NavigationState | PartialState<NavigationState> | undefined
  >(undefined);
  const {
    key: selectedDaVinciProfileKey,
    select: setSelectedDaVinciProfileKey,
    restored: daVinciSelectionRestored,
  } = useStoredSelection('selectedDaVinciProfileKey');
  const {
    key: selectedDeviceAuthProfileKey,
    select: setSelectedDeviceAuthProfileKey,
    restored: deviceAuthSelectionRestored,
  } = useStoredSelection('selectedDeviceAuthProfileKey');
  /** True once Protect has initialized successfully (mount-only). */
  const [protectReady, setProtectReady] = useState(false);
  /** Protect startup failure message — blocks DaVinci flows until retried. */
  const [protectError, setProtectError] = useState<string | null>(null);
  /** Guard so the mount-only Protect effect never re-runs native initialize. */
  const protectStartRef = useRef(false);

  const customConfigs = useCustomConfigs();
  const sampleAppClientProfiles = useMemo(
    () => [
      ...bundledProfiles,
      ...customConfigs.presets.flatMap(createPresetProfiles),
    ],
    [customConfigs.presets],
  );

  const deviceAuthProfiles = useMemo(
    () =>
      sampleAppClientProfiles.filter(profile => profile.group === 'Auth Grant'),
    [sampleAppClientProfiles],
  );

  const daVinciProfiles = useMemo(
    () =>
      sampleAppClientProfiles.filter(profile => profile.group === 'DaVinci'),
    [sampleAppClientProfiles],
  );

  const selectedDaVinciProfile = useMemo(
    () =>
      daVinciProfiles.find(
        profile => profile.key === selectedDaVinciProfileKey,
      ) ?? null,
    [daVinciProfiles, selectedDaVinciProfileKey],
  );

  const selectedDeviceAuthProfile = useMemo(
    () =>
      deviceAuthProfiles.find(
        profile => profile.key === selectedDeviceAuthProfileKey,
      ) ?? null,
    [deviceAuthProfiles, selectedDeviceAuthProfileKey],
  );

  const deviceAuthProviderClient =
    selectedDeviceAuthProfile?.deviceAuthClient ?? unconfiguredDeviceAuthClient;

  useEffect(
    () => () => disposeProfileClients(selectedDeviceAuthProfile),
    [selectedDeviceAuthProfile],
  );

  // Mount-only Protect startup — PingOne Protect does not guarantee idempotent
  // client initialization, so profile changes must never re-fire native
  // `initialize`. Readiness is consumed by the DaVinci gate below.
  useEffect(() => {
    if (protectStartRef.current) {
      return;
    }
    protectStartRef.current = true;
    const isMounted = true;
    void startProtect({ logger: logger({ level: 'debug' }) }).then(
      () => {
        if (isMounted) setProtectReady(true);
      },
      error => {
        console.warn('Failed to initialize Protect', error);
        if (isMounted) {
          // Keep `protectReady` false — the DaVinci gate blocks flows instead
          // of letting them run against an uninitialized Protect SDK.
          setProtectError(
            error instanceof Error
              ? error.message
              : 'Failed to initialize Protect',
          );
        }
      },
    );
  }, []);

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
  }, []);

  // Protect startup gates only the DaVinci flow — Auth Grant demos are
  // unaffected. Failure keeps the gate closed (see the mount-only effect).
  const davinciGate: React.ReactNode = protectReady ? null : (
    <View style={commonStyles.container}>
      <Text style={commonStyles.textError}>
        {protectError
          ? `Protect failed to initialize: ${protectError}`
          : 'Initializing Protect...'}
      </Text>
    </View>
  );

  if (
    !daVinciSelectionRestored ||
    !deviceAuthSelectionRestored ||
    !customConfigs.restored
  ) {
    return null;
  }

  const selectedConfigName = `DaVinci: ${
    selectedDaVinciProfile?.name ?? 'None'
  } | Auth Grant: ${selectedDeviceAuthProfile?.name ?? 'None'}`;

  const requireDaVinci = (
    props: RouteProps,
    screen: React.ReactElement,
  ): React.ReactElement =>
    selectedDaVinciProfile ? (
      screen
    ) : (
      <ConfigurationRequiredScreen
        {...props}
        message="Please select a DaVinci configuration first."
      />
    );

  const navigator = (
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
        <Stack.Screen name="Configuration" options={{ title: 'Configuration' }}>
          {props => (
            <ConfigurationScreen
              {...props}
              profiles={sampleAppClientProfiles}
              selectedDaVinciProfileKey={selectedDaVinciProfile?.key ?? null}
              onSelectDaVinciProfile={setSelectedDaVinciProfileKey}
              selectedDeviceAuthProfileKey={
                selectedDeviceAuthProfile?.key ?? null
              }
              onSelectDeviceAuthProfile={setSelectedDeviceAuthProfileKey}
              onAddCustomConfig={customConfigs.add}
              onDeleteCustomConfig={customConfigs.remove}
            />
          )}
        </Stack.Screen>
        <Stack.Screen name="ConfigEditor" options={{ title: 'Configuration' }}>
          {props => (
            <ConfigEditorScreen
              {...props}
              onAdd={customConfigs.add}
              onUpdate={customConfigs.update}
            />
          )}
        </Stack.Screen>
        <Stack.Screen
          name="DeviceAuthorization"
          options={{ title: 'Device Authorization' }}
        >
          {props => <DeviceAuthorizationScreen {...props} />}
        </Stack.Screen>
        <Stack.Screen
          name="ApproveDevice"
          component={ApproveDeviceScreen}
          options={{ title: 'Approve Device' }}
        />
        <Stack.Screen name="UserProfile" options={{ title: 'User Profile' }}>
          {props => requireDaVinci(props, <UserProfileScreen {...props} />)}
        </Stack.Screen>
        <Stack.Screen name="Token" options={{ title: 'Token' }}>
          {props => requireDaVinci(props, <TokenScreen />)}
        </Stack.Screen>
        <Stack.Screen name="Logout" options={{ title: 'Logout' }}>
          {props => requireDaVinci(props, <LogoutScreen />)}
        </Stack.Screen>
        <Stack.Screen name="DaVinci" options={{ title: 'DaVinci Flow' }}>
          {props =>
            requireDaVinci(
              props,
              davinciGate ?? (
                <DaVinciScreen
                  {...props}
                  externalIdpRedirectUri={selectedDaVinciProfile?.redirectUri}
                />
              ),
            )
          }
        </Stack.Screen>
      </Stack.Navigator>
    </NavigationContainer>
  );

  return (
    // DaVinci and device-grant hooks resolve clients from these contexts. The
    // DaVinci client cannot be created without a config, so its provider only
    // mounts once a DaVinci configuration is selected.
    <DeviceAuthGrantProvider
      key={profileRevision(selectedDeviceAuthProfile)}
      client={deviceAuthProviderClient}
    >
      {selectedDaVinciProfile?.daVinciConfig ? (
        <DaVinciProvider
          key={profileRevision(selectedDaVinciProfile)}
          config={selectedDaVinciProfile.daVinciConfig}
        >
          {navigator}
        </DaVinciProvider>
      ) : (
        navigator
      )}
    </DeviceAuthGrantProvider>
  );
}
