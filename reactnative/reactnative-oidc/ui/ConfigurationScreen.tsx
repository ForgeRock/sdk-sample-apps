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
import { colors } from '../src/styles/colors';
import { commonStyles } from '../src/styles/common';

type Props = NativeStackScreenProps<RootStackParamList, 'Configuration'> & {
  profiles: readonly SampleAppClientProfile[];
  selectedOidcProfileKey: string | null;
  onSelectOidcProfile: (profileKey: string) => void;
};

/**
 * Sample app configuration selector screen.
 *
 * @param props Screen props.
 * @returns Configuration selector screen.
 */
export default function ConfigurationScreen(props: Props): React.ReactElement {
  const { profiles, selectedOidcProfileKey, onSelectOidcProfile } = props;

  return (
    <ScrollView
      style={commonStyles.configScreen}
      contentContainerStyle={commonStyles.configScreenContent}
      showsVerticalScrollIndicator={false}
    >
      <View style={commonStyles.configSection}>
        <Text style={commonStyles.configSectionTitle}>OIDC (Web)</Text>

        {profiles.map(profile => {
          const selected = profile.key === selectedOidcProfileKey;
          const iconName = selected ? 'check' : 'check-box-outline-blank';
          return (
            <TouchableOpacity
              key={profile.key}
              style={commonStyles.configOptionRow}
              onPress={() => onSelectOidcProfile(profile.key)}
              accessibilityRole="radio"
              accessibilityState={{ selected }}
            >
              <View style={commonStyles.configOptionTextBlock}>
                <Text style={commonStyles.configOptionName}>
                  {profile.name}
                </Text>
                <Text style={commonStyles.configOptionMeta}>
                  {profile.host}
                </Text>
                <Text style={commonStyles.configOptionMeta}>
                  {profile.environment}
                </Text>
              </View>
              <MaterialIcon
                name={iconName}
                size={28}
                color={selected ? colors.primary : colors.textDark}
              />
            </TouchableOpacity>
          );
        })}
      </View>
    </ScrollView>
  );
}
