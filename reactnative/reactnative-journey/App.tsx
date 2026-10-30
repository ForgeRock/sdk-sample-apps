/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React, { useEffect, useMemo, useState, useRef } from 'react';
import {
  NavigationContainer,
  type NavigationState,
  type PartialState,
} from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { Pressable, Text, TextInput, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import MultiStorageScreen from './ui/MultiStorageScreen';
import HomeScreen from './ui/HomeScreen';
import ConfigurationScreen from './ui/ConfigurationScreen';
import JourneyRouteScreen from './ui/JourneyRouteScreen';
import JourneyHelperScreen from './ui/JourneyHelperScreen';
import JourneyFullScreen from './ui/JourneyFullScreen';
import BrowserScreen from './ui/BrowserScreen';
import LoggerScreen from './ui/LoggerScreen';
import DeviceAuthorizationScreen from './ui/DeviceAuthorizationScreen';
import ApproveDeviceScreen from './ui/ApproveDeviceScreen';
import DeviceProfileScreen from './ui/DeviceProfileScreen';
import DevicesScreen from './ui/DevicesScreen';
import UserProfileScreen from './ui/UserProfileScreen';
import TokenScreen from './ui/TokenScreen';
import LogoutScreen from './ui/LogoutScreen';
import BindingKeysScreen from './ui/BindingKeysScreen';
import PushScreen from './ui/push/PushScreen';
import PushNotificationsScreen from './ui/push/PushNotificationsScreen';
import { PushNotificationProvider } from './ui/push/PushNotificationProvider';
import OathTokensScreen from './ui/OathTokensScreen';
import QRScannerScreen from './ui/QRScannerScreen';
import { JourneyProvider } from '@ping-identity/rn-journey';
import { DeviceAuthGrantProvider } from '@ping-identity/rn-oidc';
import {
  createPresetProfiles,
  sampleAppClientProfiles as bundledProfiles,
  setActiveJourneyConnection,
  unconfiguredDeviceAuthClient,
  type SampleAppClientProfile,
} from './src/clients';
import { useStoredSelection } from './src/config/useStoredSelection';
import { useCustomConfigs } from './src/config/useCustomConfigs';
import ConfigEditorScreen from './ui/ConfigEditorScreen';
import type { ConfigEditorParams } from './src/config/useConfigActions';
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
  Storage: undefined;
  JourneyRoute: { verificationUri?: string } | undefined;
  JourneyHelper: { journeyName?: string; verificationUri?: string } | undefined;
  JourneyFull: undefined;
  Browser: undefined;
  Logger: undefined;
  DeviceAuthorization: undefined;
  ApproveDevice: { verificationUri?: string } | undefined;
  DeviceProfile: undefined;
  Devices: undefined;
  UserProfile: undefined;
  Token: undefined;
  Logout: undefined;
  BindingKeys: undefined;
  Push: undefined;
  PushNotifications: undefined;
  OathTokens: undefined;
  QRScanner: undefined;
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
 * Releases the lazily built clients of a JSON preset profile when it is
 * deselected. `.env` profiles share long-lived clients and are left alone.
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
 * Provider key that changes when a custom config is edited, so providers
 * rebuild against the updated client.
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
 * Root sample app component that wires navigation and initializes demo clients.
 *
 * ## Structure
 *
 * 1. **Profile selection** — `sampleAppClientProfiles` (defined in `src/clients.ts`) lists
 *    client configurations: the bundled `assets/configs/*.json` presets plus custom configs. The active profile is stored as `selectedJourneyProfileKey` and restored from
 *    AsyncStorage on start; with no stored selection the Journey routes show Configuration Required.
 *
 * 2. **Client initialization** — whenever `selectedJourneyProfile` changes the component calls
 *    `journeyClient.init()` inside a guarded async effect. Init errors are surfaced as an
 *    inline message instead of crashing.
 *
 * 3. **Context providers** — `JourneyProvider` and `DeviceAuthGrantProvider` expose the
 *    active clients to every screen via React context so screens do not import clients
 *    directly.
 *
 * 4. **Navigation** — a `NativeStackNavigator` registers all demo screens.
 *
 * 5. **Global SDK setup** — `configureBrowser` is called once per effect cycle to set
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
  /** Non-null while the journey client failed to initialise after a profile switch. */
  const [initError, setInitError] = useState<string | null>(null);
  const {
    key: selectedJourneyProfileKey,
    select: setSelectedJourneyProfileKey,
    restored: journeySelectionRestored,
  } = useStoredSelection('selectedJourneyProfileKey');
  const {
    key: selectedDeviceAuthProfileKey,
    select: setSelectedDeviceAuthProfileKey,
    restored: deviceAuthSelectionRestored,
  } = useStoredSelection('selectedDeviceAuthProfileKey');

  const customConfigs = useCustomConfigs();
  const sampleAppClientProfiles = useMemo(
    () => [
      ...bundledProfiles,
      ...customConfigs.presets.flatMap(createPresetProfiles),
    ],
    [customConfigs.presets],
  );

  const journeyProfiles = useMemo(
    () =>
      sampleAppClientProfiles.filter(profile => profile.group === 'Journey'),
    [sampleAppClientProfiles],
  );
  const deviceAuthProfiles = useMemo(
    () =>
      sampleAppClientProfiles.filter(profile => profile.group === 'Auth Grant'),
    [sampleAppClientProfiles],
  );

  const selectedJourneyProfile = useMemo(
    () =>
      journeyProfiles.find(
        profile => profile.key === selectedJourneyProfileKey,
      ) ?? null,
    [journeyProfiles, selectedJourneyProfileKey],
  );
  const selectedDeviceAuthProfile = useMemo(
    () =>
      deviceAuthProfiles.find(
        profile => profile.key === selectedDeviceAuthProfileKey,
      ) ?? null,
    [deviceAuthProfiles, selectedDeviceAuthProfileKey],
  );

  const journeyProviderClient =
    selectedJourneyProfile?.journeyClient ?? journeyProfiles[0]?.journeyClient;
  const deviceAuthProviderClient =
    selectedDeviceAuthProfile?.deviceAuthClient ?? unconfiguredDeviceAuthClient;

  useEffect(() => {
    setActiveJourneyConnection(selectedJourneyProfile?.connection);
  }, [selectedJourneyProfile]);

  useEffect(
    () => () => disposeProfileClients(selectedJourneyProfile),
    [selectedJourneyProfile],
  );
  useEffect(
    () => () => disposeProfileClients(selectedDeviceAuthProfile),
    [selectedDeviceAuthProfile],
  );

  useEffect(() => {
    let isMounted = true;
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

    // Initialize selected Journey client after profile switches.
    const initializeJourneyClient = async (): Promise<void> => {
      if (!selectedJourneyProfile) {
        if (isMounted) {
          setInitError(null);
        }
        return;
      }

      try {
        await Promise.resolve(selectedJourneyProfile.journeyClient?.init());
        if (isMounted) {
          setInitError(null);
        }
      } catch (error) {
        console.error('Failed to initialize Journey client', error);
        if (isMounted) {
          const message =
            error instanceof Error
              ? error.message
              : 'Failed to initialize Journey client.';
          setInitError(message);
        }
      }
    };

    void initializeJourneyClient();

    // Browser defaults used by external IdP / browser flows in this sample app.
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

    return () => {
      isMounted = false;
    };
  }, [browserLogger, selectedJourneyProfile]);

  if (
    !journeySelectionRestored ||
    !deviceAuthSelectionRestored ||
    !customConfigs.restored
  ) {
    return null;
  }

  if (initError) {
    // Fail fast with a clear startup error instead of crashing on first journey API call.
    return <Text>{`Journey client init failed: ${initError}`}</Text>;
  }

  const selectedConfigName = `Journey: ${
    selectedJourneyProfile?.name ?? 'None'
  } | Auth Grant: ${selectedDeviceAuthProfile?.name ?? 'None'}`;

  if (!journeyProviderClient) {
    return (
      <Text>
        No Journey configuration is available. Add a JSON file to
        assets/configs.
      </Text>
    );
  }

  return (
    // Journey and device-grant hooks resolve clients from these contexts.
    <JourneyProvider
      key={profileRevision(selectedJourneyProfile)}
      client={journeyProviderClient}
    >
      <DeviceAuthGrantProvider
        key={profileRevision(selectedDeviceAuthProfile)}
        client={deviceAuthProviderClient}
      >
        <PushNotificationProvider>
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
                  <HomeScreen
                    {...props}
                    selectedConfigName={selectedConfigName}
                  />
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
                    selectedJourneyProfileKey={selectedJourneyProfileKey}
                    selectedDeviceAuthProfileKey={
                      selectedDeviceAuthProfile?.key ?? null
                    }
                    onSelectJourneyProfile={setSelectedJourneyProfileKey}
                    onSelectDeviceAuthProfile={setSelectedDeviceAuthProfileKey}
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
              <Stack.Screen
                name="Storage"
                component={MultiStorageScreen}
                options={{ title: 'Storage' }}
              />
              <Stack.Screen
                name="JourneyRoute"
                options={{ title: 'Journey Configuration' }}
              >
                {props =>
                  selectedJourneyProfile ? (
                    <JourneyRouteScreen {...props} />
                  ) : (
                    <ConfigurationRequiredScreen
                      {...props}
                      message="Please select a Journey configuration first."
                    />
                  )
                }
              </Stack.Screen>
              <Stack.Screen
                name="JourneyHelper"
                options={{ title: 'Journey Flow' }}
              >
                {props =>
                  selectedJourneyProfile ? (
                    <JourneyHelperScreen
                      {...props}
                      journeyClient={journeyProviderClient}
                      externalIdpRedirectUri={
                        selectedJourneyProfile.externalIdpRedirectUri
                      }
                    />
                  ) : (
                    <ConfigurationRequiredScreen
                      {...props}
                      message="Please select a Journey configuration first."
                    />
                  )
                }
              </Stack.Screen>
              <Stack.Screen
                name="JourneyFull"
                options={{ title: 'Journey Full (API)' }}
              >
                {props =>
                  selectedJourneyProfile ? (
                    <JourneyFullScreen />
                  ) : (
                    <ConfigurationRequiredScreen
                      {...props}
                      message="Please select a Journey configuration first."
                    />
                  )
                }
              </Stack.Screen>
              <Stack.Screen
                name="Browser"
                component={BrowserScreen}
                options={{ title: 'Browser Demo' }}
              />
              <Stack.Screen
                name="Logger"
                component={LoggerScreen}
                options={{ title: 'Logger Demo' }}
              />
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
              <Stack.Screen
                name="DeviceProfile"
                component={DeviceProfileScreen}
                options={{ title: 'Device Profile' }}
              />
              <Stack.Screen
                name="Devices"
                component={DevicesScreen}
                options={{ title: 'Device Management' }}
              />
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
              <Stack.Screen
                name="BindingKeys"
                component={BindingKeysScreen}
                options={{ title: 'Binding Keys' }}
              />
              <Stack.Screen
                name="Push"
                component={PushScreen}
                options={{ title: 'Push Authenticator' }}
              />
              <Stack.Screen
                name="PushNotifications"
                component={PushNotificationsScreen}
                options={{ title: 'Push Notifications' }}
              />
              <Stack.Screen
                name="OathTokens"
                component={OathTokensScreen}
                options={{ title: 'OATH Tokens' }}
              />
              <Stack.Screen
                name="QRScanner"
                component={QRScannerScreen}
                options={{ title: 'QR Scanner' }}
              />
            </Stack.Navigator>
          </NavigationContainer>
        </PushNotificationProvider>
      </DeviceAuthGrantProvider>
    </JourneyProvider>
  );
}
