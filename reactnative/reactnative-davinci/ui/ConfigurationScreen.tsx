/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { ScrollView, Text, TouchableOpacity, View } from 'react-native';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { RootStackParamList } from '../App';
import type { SampleAppClientProfile } from '../src/clients';
import type { ConfigFields, ConfigKind } from '../src/config/customConfigs';
import { useConfigActions } from '../src/config/useConfigActions';
import { colors } from '../src/styles/colors';
import { commonStyles } from '../src/styles/common';
import ConfigCard from './components/molecules/ConfigCard';
import ConfigRowActions from './components/molecules/ConfigRowActions';

type Props = NativeStackScreenProps<RootStackParamList, 'Configuration'> & {
  profiles: readonly SampleAppClientProfile[];
  selectedDaVinciProfileKey: string | null;
  onSelectDaVinciProfile: (profileKey: string) => void;
  selectedDeviceAuthProfileKey: string | null;
  onSelectDeviceAuthProfile: (profileKey: string) => void;
  onAddCustomConfig: (kind: ConfigKind, fields: ConfigFields) => void;
  onDeleteCustomConfig: (id: string) => void;
};

/**
 * Sample app configuration selector screen.
 *
 * @param props Screen props.
 * @returns Configuration selector screen.
 */
export default function ConfigurationScreen(props: Props): React.ReactElement {
  const {
    navigation,
    profiles,
    selectedDaVinciProfileKey,
    onSelectDaVinciProfile,
    selectedDeviceAuthProfileKey,
    onSelectDeviceAuthProfile,
    onAddCustomConfig,
    onDeleteCustomConfig,
  } = props;

  const actions = useConfigActions(
    params => navigation.navigate('ConfigEditor', params),
    onAddCustomConfig,
    onDeleteCustomConfig,
  );

  const renderRow = (
    profile: SampleAppClientProfile,
    selected: boolean,
    onSelect: (key: string) => void,
    meta: string[],
  ): React.ReactNode => (
    <TouchableOpacity
      key={profile.key}
      style={commonStyles.configOptionRow}
      onPress={() => onSelect(profile.key)}
      accessibilityRole="radio"
      accessibilityState={{ selected }}
    >
      <View style={commonStyles.configOptionTextBlock}>
        <Text style={commonStyles.configOptionName}>{profile.name}</Text>
        {meta.map(line => (
          <Text key={line} style={commonStyles.configOptionMeta}>
            {line}
          </Text>
        ))}
      </View>
      <ConfigRowActions
        profile={profile}
        onDuplicate={actions.duplicate}
        onEdit={actions.edit}
        onDelete={actions.remove}
      />
      <MaterialIcon
        name={selected ? 'check' : 'check-box-outline-blank'}
        size={28}
        color={selected ? colors.primary : colors.textDark}
      />
    </TouchableOpacity>
  );

  return (
    <ScrollView
      style={commonStyles.configScreen}
      contentContainerStyle={commonStyles.configScreenContent}
      showsVerticalScrollIndicator={false}
    >
      <ConfigCard
        title="DaVinci"
        profiles={profiles.filter(profile => profile.group === 'DaVinci')}
        onAdd={() => actions.add('davinci')}
        renderRow={profile =>
          renderRow(
            profile,
            profile.key === selectedDaVinciProfileKey,
            onSelectDaVinciProfile,
            [profile.host, profile.environment],
          )
        }
      />
      <ConfigCard
        title="Auth Grant"
        profiles={profiles.filter(profile => profile.group === 'Auth Grant')}
        onAdd={() => actions.add('deviceAuth')}
        renderRow={profile => {
          const config = profile.deviceAuthConfig;
          return renderRow(
            profile,
            profile.key === selectedDeviceAuthProfileKey,
            onSelectDeviceAuthProfile,
            [
              config?.discoveryEndpoint || 'Discovery endpoint not configured',
              `${config?.clientId || 'Client ID not configured'} · ${
                config?.scopes.join(', ') || 'No scopes configured'
              }`,
            ],
          );
        }}
      />
    </ScrollView>
  );
}
