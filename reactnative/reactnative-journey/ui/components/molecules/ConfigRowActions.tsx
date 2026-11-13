/*
 * Copyright (c) 2026 Ping Identity Corporation. All rights reserved.
 *
 * This software may be modified and distributed under the terms
 * of the MIT license. See the LICENSE file for details.
 */

import React from 'react';
import { TouchableOpacity, View } from 'react-native';
import MaterialIcon from 'react-native-vector-icons/MaterialIcons';
import type { SampleAppClientProfile } from '../../../src/clients';
import { colors } from '../../../src/styles/colors';

type Props = {
  profile: SampleAppClientProfile;
  onDuplicate: (profile: SampleAppClientProfile) => void;
  onEdit: (profile: SampleAppClientProfile) => void;
  onDelete: (profile: SampleAppClientProfile) => void;
};

/**
 * Row actions matching: bundled presets can be
 * duplicated; custom configs can also be edited and deleted.
 *
 * @param props Profile and action callbacks.
 * @returns Action icons.
 */
export default function ConfigRowActions(props: Props): React.ReactElement {
  const { profile, onDuplicate, onEdit, onDelete } = props;
  const isCustom = profile.source === 'custom';
  return (
    <View style={{ flexDirection: 'row', alignItems: 'center' }}>
      <TouchableOpacity
        onPress={() => onDuplicate(profile)}
        accessibilityLabel="Duplicate"
      >
        <MaterialIcon name="content-copy" size={22} color={colors.textDark} />
      </TouchableOpacity>
      {isCustom ? (
        <>
          <TouchableOpacity
            onPress={() => onEdit(profile)}
            accessibilityLabel="Edit"
            style={{ marginLeft: 12 }}
          >
            <MaterialIcon name="edit" size={22} color={colors.textDark} />
          </TouchableOpacity>
          <TouchableOpacity
            onPress={() => onDelete(profile)}
            accessibilityLabel="Delete"
            style={{ marginHorizontal: 12 }}
          >
            <MaterialIcon name="delete" size={22} color={colors.textDark} />
          </TouchableOpacity>
        </>
      ) : (
        <View style={{ width: 12 }} />
      )}
    </View>
  );
}
