/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { SampleAppClientProfile } from '../../../src/clients';
import { colors } from '../../../src/styles/colors';
import { commonStyles } from '../../../src/styles/common';

type Props = {
  title: string;
  profiles: readonly SampleAppClientProfile[];
  onAdd?: () => void;
  renderRow: (profile: SampleAppClientProfile) => React.ReactNode;
};

const SOURCES: ReadonlyArray<{
  source: SampleAppClientProfile['source'];
  label: string;
}> = [
  { source: 'json', label: 'Presets' },
  { source: 'custom', label: 'Custom' },
];

/**
 * Card for one configuration kind: bundled presets and custom
 * configs, with an add button.
 *
 * @param props Card title, profiles, add handler and row renderer.
 * @returns Config card.
 */
export default function ConfigCard(props: Props): React.ReactElement {
  const { title, profiles, onAdd, renderRow } = props;
  return (
    <View style={commonStyles.configSection}>
      <View
        style={{
          flexDirection: 'row',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Text style={commonStyles.configSectionTitle}>{title}</Text>
        {onAdd ? (
          <TouchableOpacity onPress={onAdd} accessibilityLabel="Add config">
            <MaterialIcon name="add" size={28} color={colors.primary} />
          </TouchableOpacity>
        ) : null}
      </View>
      {SOURCES.map(({ source, label }) => {
        const items = profiles.filter(profile => profile.source === source);
        return items.length === 0 ? null : (
          <View key={source}>
            <Text style={commonStyles.configOptionMeta}>{label}</Text>
            {items.map(renderRow)}
          </View>
        );
      })}
      {profiles.length === 0 ? (
        <Text style={commonStyles.configOptionMeta}>
          No configurations. Tap + to add one.
        </Text>
      ) : null}
    </View>
  );
}
